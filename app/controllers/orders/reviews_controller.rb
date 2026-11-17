# US10: avaliação de cada cupcake e da entrega, depois que o pedido foi entregue.
class Orders::ReviewsController < ApplicationController
  require_role :customer

  def create
    order = current_user.orders.find_by!(code: params[:order_id])
    review = order.reviews.build(review_params.merge(user: current_user))
    if review.save
      redirect_to order_path(order), success: "Obrigado pela avaliação!"
    else
      redirect_to order_path(order), error: review.errors.map(&:message).uniq.to_sentence
    end
  end

  private

  def review_params
    params.expect(review: [ :cupcake_id, :rating, :delivery_rating, :comment ])
  end
end
