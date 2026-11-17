# Meus pedidos e acompanhamento do pedido (US09).
class OrdersController < ApplicationController
  require_role :customer

  def index
    @orders = current_user.orders.recent_first
  end

  def show
    @order = current_user.orders.includes(items: :cupcake).find_by!(code: params[:id])
    @reviewed_cupcake_ids = @order.reviews.pluck(:cupcake_id)
  end
end
