class Address < ApplicationRecord
  belongs_to :user

  validates :street, :number, :district, :zip_code, presence: true

  def to_s
    "#{street}, #{number} – #{district}, CEP #{zip_code}"
  end
end
