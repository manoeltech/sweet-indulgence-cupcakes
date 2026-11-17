class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :cupcake

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  def subtotal
    unit_price * quantity
  end
end
