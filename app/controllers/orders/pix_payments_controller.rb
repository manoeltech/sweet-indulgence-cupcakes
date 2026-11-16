# Simula o aviso do banco de que o PIX foi pago (em produção viria do gateway).
class Orders::PixPaymentsController < ApplicationController
  require_role :customer

  def create
    order = current_user.orders.find_by!(code: params[:order_id])
    order.confirm_pix!
    redirect_to order_confirmation_path(order), success: "Pagamento PIX confirmado!"
  rescue BusinessRuleError => error
    redirect_to order_confirmation_path(order), error: error.message
  end
end
