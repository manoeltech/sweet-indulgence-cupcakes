# US10: o cliente avalia cada cupcake e a entrega depois de receber o pedido.
class Review < ApplicationRecord
  belongs_to :user
  belongs_to :order
  belongs_to :cupcake

  validates :rating, :delivery_rating, numericality: { only_integer: true, in: 1..5, message: "Dê uma nota de 1 a 5 estrelas para o cupcake e para a entrega." }
  validates :cupcake_id, uniqueness: { scope: :order_id, message: "Você já avaliou este item." }
  validates :comment, length: { maximum: 1000 }
  validate :order_delivered
  validate :cupcake_in_order

  private

  def order_delivered # US10 RN#1: só avalia quem recebeu o pedido
    errors.add(:base, "Você poderá avaliar depois que o pedido for entregue.") unless order&.delivered?
  end

  def cupcake_in_order
    errors.add(:base, "Este cupcake não faz parte do pedido.") if order && !order.items.exists?(cupcake_id: cupcake_id)
  end
end
