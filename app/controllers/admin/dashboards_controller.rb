# US13: painel de pedidos por estado; por padrão só os ativos (RN#1).
class Admin::DashboardsController < Admin::BaseController
  FILTERS = { "awaiting_payment" => "Aguardando PIX", "paid" => "Pendentes", "preparing" => "Em preparação",
              "out_for_delivery" => "Em entrega", "ready_for_pickup" => "Retirada", "delivered" => "Concluídos",
              "canceled" => "Cancelados" }.freeze

  def show
    @filter = params[:status].presence_in(FILTERS.keys) || "active"
    @orders = (@filter == "active" ? Order.active : Order.where(status: @filter))
      .includes(:customer, :courier, items: :cupcake).recent_first.limit(100)
    @counts = Order.group(:status).count
    @sales_today = Order.where(created_at: Time.zone.today.all_day).where.not(status: %w[canceled awaiting_payment]).sum(:total)
    @low_stock = Cupcake.low_stock
    @couriers = User.courier.order(:name)
  end
end
