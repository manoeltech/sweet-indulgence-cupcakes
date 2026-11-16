# US07 RN#1: o frete varia conforme a zona de entrega.
class DeliveryZone < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :fee, numericality: { greater_than_or_equal_to: 0 }
end
