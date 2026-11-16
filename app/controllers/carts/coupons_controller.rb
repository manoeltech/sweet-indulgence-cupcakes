# US06: aplicar e remover o cupom de desconto.
class Carts::CouponsController < ApplicationController
  def create
    coupon = cart.apply_coupon(params[:code])
    if coupon
      redirect_to cart_path, success: "Cupom #{coupon.code} aplicado!"
    else
      redirect_to cart_path
    end
  rescue BusinessRuleError => error
    redirect_to cart_path, error: error.message
  end

  def destroy
    cart.remove_coupon
    redirect_to cart_path
  end
end
