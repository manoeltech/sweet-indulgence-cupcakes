class Order < ApplicationRecord
  PICKUP_MINUTES = 30            # US07 RN#2
  MAX_ACTIVE_DELIVERIES = 3      # US14 RN#1
  STORE_ADDRESS = "Rua das Confeitarias, 100 – Centro".freeze

  STATUS_LABELS = {
    "awaiting_payment" => "Aguardando pagamento",
    "paid" => "Pagamento aprovado",
    "preparing" => "Em preparação",
    "out_for_delivery" => "Saiu para entrega",
    "ready_for_pickup" => "Pronto para retirada",
    "delivered" => "Entregue",
    "canceled" => "Cancelado"
  }.freeze
  ACTIVE_STATUSES = %w[awaiting_payment paid preparing out_for_delivery ready_for_pickup].freeze
  # Transições permitidas para o administrador (o entregador só marca "entregue").
  TRANSITIONS = {
    "awaiting_payment" => %w[canceled],
    "paid" => %w[preparing canceled],
    "preparing" => %w[out_for_delivery ready_for_pickup canceled],
    "out_for_delivery" => %w[delivered],
    "ready_for_pickup" => %w[delivered]
  }.freeze
  PAYMENT_LABELS = { "credit" => "Crédito", "debit" => "Débito", "pix" => "PIX" }.freeze

  enum :status, STATUS_LABELS.keys.index_by(&:itself)
  enum :fulfillment, { delivery: "delivery", pickup: "pickup" }
  enum :payment_method, { credit: "credit", debit: "debit", pix: "pix" }, suffix: :payment

  belongs_to :customer, class_name: "User", inverse_of: :orders
  belongs_to :courier, class_name: "User", optional: true, inverse_of: :deliveries
  belongs_to :coupon, optional: true
  belongs_to :delivery_zone, optional: true
  has_many :items, class_name: "OrderItem", dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :contact_logs, dependent: :destroy

  before_validation :generate_code, on: :create

  scope :active, -> { where(status: ACTIVE_STATUSES) }
  scope :recent_first, -> { order(created_at: :desc) }

  def to_param
    code
  end

  def status_label
    STATUS_LABELS.fetch(status)
  end

  def payment_label
    PAYMENT_LABELS.fetch(payment_method)
  end

  # Só os próximos passos que fazem sentido: pedido de retirada não "sai para entrega" e vice-versa.
  def next_statuses
    skipped = delivery? ? "ready_for_pickup" : "out_for_delivery"
    TRANSITIONS.fetch(status, []) - [ skipped ]
  end

  def active?
    status.in?(ACTIVE_STATUSES)
  end

  # Linha do tempo da tela de acompanhamento.
  def timeline
    [ "paid", "preparing", delivery? ? "out_for_delivery" : "ready_for_pickup", "delivered" ]
  end

  # ---------- CU01 – Realizar pedido ----------
  def self.place!(customer:, cart:, fulfillment:, payment_method:, address: nil, delivery_zone_id: nil,
                  coupon_code: nil, card: {}, gateway: SimulatedGateway.new)
    raise BusinessRuleError, "Seu carrinho está vazio." if cart.empty?
    raise BusinessRuleError, "Escolha entrega ou retirada na loja." unless fulfillments.key?(fulfillment)
    raise BusinessRuleError, "Escolha a forma de pagamento." unless payment_methods.key?(payment_method)

    transaction do
      order = new(customer: customer, fulfillment: fulfillment, payment_method: payment_method)
      order.add_items(cart)
      order.apply_coupon(Coupon.find_valid!(coupon_code)) # RN#2: só um cupom por pedido
      order.set_delivery(delivery_zone_id, address) if order.delivery?
      order.total = order.subtotal - order.discount + order.shipping_fee
      order.charge(card, gateway)                         # CU01-B: o cartão pode ser recusado
      order.save!
      order.reserve_stock                                 # US12 RN#1: baixa ao registrar o pedido
      order.coupon&.increment!(:uses_count)
      Notification.to_admins("Novo pedido ##{order.code} de #{customer.name} – #{order.formatted_total}")
      Notification.notify(customer, order, "Pedido ##{order.code} confirmado! Pagamento aprovado.") if order.paid?
      order
    end
  end

  def add_items(cart)
    cart.each do |cupcake_id, quantity|
      cupcake = Cupcake.active.lock.find_by(id: cupcake_id)
      raise BusinessRuleError, "Um item do carrinho não está mais disponível." if cupcake.nil?
      raise BusinessRuleError, "Só temos #{cupcake.stock} unidade(s) de #{cupcake.name}." if quantity > cupcake.stock

      items.build(cupcake: cupcake, quantity: quantity, unit_price: cupcake.price)
    end
    self.subtotal = items.sum(&:subtotal)
  end

  def apply_coupon(coupon)
    return unless coupon

    self.coupon = coupon
    self.discount = coupon.discount_on(subtotal)
  end

  def set_delivery(delivery_zone_id, address)
    zone = DeliveryZone.find_by(id: delivery_zone_id)
    raise BusinessRuleError, "Escolha o bairro/zona de entrega." if zone.nil?
    raise BusinessRuleError, "Informe o endereço de entrega." if address.blank?

    self.delivery_zone = zone
    self.shipping_fee = zone.fee
    self.delivery_address = address.strip
  end

  def charge(card, gateway)
    if pix_payment?
      self.status = "awaiting_payment"
      self.pix_code = gateway.pix_code(total)
    else
      self.card_last4 = gateway.charge_card!(card, total)
      self.status = "paid"
    end
  end

  def reserve_stock
    items.each { |item| item.cupcake.adjust_stock!(-item.quantity) }
  end

  def confirm_pix!
    raise BusinessRuleError, "Este pedido não está aguardando pagamento." unless awaiting_payment?

    update!(status: "paid")
    Notification.notify(customer, self, "Pagamento PIX do pedido ##{code} confirmado.")
  end

  # ---------- US09, US13, US14, US17 ----------
  def advance_to!(new_status, by: nil)
    unless new_status.in?(next_statuses)
      raise BusinessRuleError, "Não é possível passar de “#{status_label}” para “#{STATUS_LABELS.fetch(new_status, new_status)}”."
    end
    check_transition_rules(new_status, by)

    transaction do
      items.each { |item| item.cupcake.adjust_stock!(item.quantity) } if new_status == "canceled" # US12 RN#2
      update!(status: new_status)
      Notification.notify(customer, self, "Pedido ##{code}: #{status_label}.")
    end
  end

  def assign_courier!(new_courier)
    raise BusinessRuleError, "Pedidos de retirada não precisam de entregador." unless delivery?
    raise BusinessRuleError, "Só é possível atribuir pedidos ainda não enviados." unless paid? || preparing?
    raise BusinessRuleError, "Escolha um entregador válido." unless new_courier&.courier?

    active_count = new_courier.deliveries.where(status: %w[paid preparing out_for_delivery]).where.not(id: id).count
    if active_count >= MAX_ACTIVE_DELIVERIES
      raise BusinessRuleError, "#{new_courier.name} já tem #{active_count} entregas em andamento (máximo #{MAX_ACTIVE_DELIVERIES})."
    end

    update!(courier: new_courier)
    Notification.create!(user: new_courier, order: self, message: "Você recebeu o pedido ##{code} para entregar.")
  end

  # US15 RN#1: considera apenas pedidos concluídos (entregues), no horário de Brasília.
  def self.sales_report(from, to)
    delivered_orders = delivered.where(created_at: from.in_time_zone.beginning_of_day..to.in_time_zone.end_of_day)
    best_sellers = OrderItem.joins(:cupcake).where(order_id: delivered_orders.select(:id))
      .group("cupcakes.name").order(Arel.sql("SUM(order_items.quantity) DESC"))
      .pluck("cupcakes.name", Arel.sql("SUM(order_items.quantity)"), Arel.sql("SUM(order_items.quantity * order_items.unit_price)"))
    { orders_count: delivered_orders.count, total: delivered_orders.sum(:total), best_sellers: best_sellers }
  end

  def formatted_total
    ActiveSupport::NumberHelper.number_to_currency(total)
  end

  private

  def generate_code
    self.code ||= loop do
      candidate = SecureRandom.hex(3).upcase
      break candidate unless Order.exists?(code: candidate)
    end
  end

  def check_transition_rules(new_status, by)
    case new_status
    when "out_for_delivery"
      raise BusinessRuleError, "Atribua um entregador antes de enviar o pedido." if courier.nil?
    when "delivered"
      raise BusinessRuleError, "Este pedido não está atribuído a você." if by&.courier? && courier_id != by.id
    end
  end
end
