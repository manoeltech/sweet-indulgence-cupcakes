# Carrinho do visitante ou cliente (US04), guardado na sessão: { "id do cupcake" => quantidade }.
# Também guarda o código do cupom aplicado (US06 RN#2: um cupom por pedido).
class Cart
  Line = Struct.new(:cupcake, :quantity) do
    def subtotal
      cupcake.price * quantity
    end
  end

  def initialize(session)
    @session = session
    @session["cart"] ||= {}
  end

  def items
    @session["cart"].to_h { |id, quantity| [ id.to_i, quantity.to_i ] }
  end

  def lines
    @lines ||= begin
      cupcakes = Cupcake.active.where(id: items.keys).index_by(&:id)
      items.filter_map { |id, quantity| Line.new(cupcakes[id], quantity) if cupcakes[id] }
    end
  end

  def count
    items.values.sum
  end

  def empty?
    lines.empty?
  end

  # US04 RNF#1: nunca passa do estoque.
  def add(cupcake, quantity = 1)
    set(cupcake, quantity_of(cupcake) + [ quantity.to_i, 1 ].max)
  end

  def change(cupcake, delta)
    set(cupcake, quantity_of(cupcake) + delta)
  end

  def include?(cupcake)
    items.key?(cupcake.id)
  end

  def remove(cupcake)
    @session["cart"].delete(cupcake.id.to_s)
    @lines = nil
  end

  def clear
    @session["cart"] = {}
    @session.delete("coupon_code")
    @lines = nil
  end

  def coupon_code
    @session["coupon_code"]
  end

  def apply_coupon(code)
    coupon = Coupon.find_valid!(code)
    @session["coupon_code"] = coupon&.code
    coupon
  rescue BusinessRuleError
    @session.delete("coupon_code")
    raise
  end

  def remove_coupon
    @session.delete("coupon_code")
  end

  def subtotal
    lines.sum(&:subtotal)
  end

  # Cupom revalidado a cada exibição: pode ter expirado ou esgotado desde que foi aplicado.
  def coupon
    return @coupon if defined?(@coupon)

    @coupon = Coupon.find_valid!(coupon_code)
  rescue BusinessRuleError => error
    @coupon_error = error.message
    @coupon = nil
  end

  def coupon_error
    coupon
    @coupon_error
  end

  def discount
    coupon ? coupon.discount_on(subtotal) : 0
  end

  def total
    subtotal - discount
  end

  private

  def quantity_of(cupcake)
    items.fetch(cupcake.id, 0)
  end

  def set(cupcake, quantity)
    return remove(cupcake) if quantity <= 0
    raise BusinessRuleError, "Só temos #{cupcake.stock} unidade(s) de #{cupcake.name} em estoque." if quantity > cupcake.stock

    @session["cart"][cupcake.id.to_s] = quantity
    @lines = nil
  end
end
