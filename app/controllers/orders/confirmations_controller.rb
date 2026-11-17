class Orders::ConfirmationsController < ApplicationController
  require_role :customer

  def show
    @order = current_user.orders.find_by!(code: params[:order_id])
  end
end
