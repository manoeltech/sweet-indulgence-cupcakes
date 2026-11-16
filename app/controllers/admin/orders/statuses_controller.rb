# US13: o administrador avança o pedido (ou cancela, devolvendo o estoque).
class Admin::Orders::StatusesController < Admin::BaseController
  def update
    order = Order.find_by!(code: params[:order_id])
    order.advance_to!(params[:status])
    redirect_back fallback_location: admin_root_path, success: "Pedido ##{order.code}: #{order.status_label}."
  end
end
