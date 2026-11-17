# US14: atribui o entregador (no máximo 3 entregas em andamento por entregador).
class Admin::Orders::CouriersController < Admin::BaseController
  def update
    order = Order.find_by!(code: params[:order_id])
    courier = User.courier.find_by(id: params[:courier_id])
    order.assign_courier!(courier)
    redirect_back fallback_location: admin_root_path, success: "Pedido ##{order.code} atribuído a #{courier.name}."
  end
end
