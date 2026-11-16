# CU01 – Realizar pedido: entrega ou retirada (US07) e pagamento (US08).
class CheckoutsController < ApplicationController
  require_role :customer
  before_action :require_items

  def new
    @form = {}
  end

  def create
    @form = checkout_params
    order = Order.place!(
      customer: current_user,
      cart: cart.items,
      fulfillment: @form[:fulfillment],
      payment_method: @form[:payment_method],
      address: chosen_address,
      delivery_zone_id: @form[:delivery_zone_id],
      coupon_code: cart.coupon_code,
      card: @form.fetch(:card, {})
    )
    cart.clear
    redirect_to order_confirmation_path(order)
  rescue BusinessRuleError => error # CU01-A (cupom) e CU01-B (pagamento recusado)
    flash.now[:error] = error.message
    render :new, status: :unprocessable_entity
  end

  private

  def require_items
    redirect_to root_path, warning: "Seu carrinho está vazio." if cart.empty?
  end

  def checkout_params
    params.expect(checkout: [ :fulfillment, :payment_method, :delivery_zone_id, :saved_address_id, :address,
                              card: [ :number, :name, :expiry, :cvv ] ])
  end

  def chosen_address
    saved = current_user.addresses.find_by(id: @form[:saved_address_id]) if @form[:saved_address_id].present?
    saved&.to_s || @form[:address]
  end
end
