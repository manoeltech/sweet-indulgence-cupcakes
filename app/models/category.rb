class Category < ApplicationRecord
  ICONS = { "chocolate" => "🍫", "frutas" => "🍓", "classicos" => "🧁", "diet" => "🌿", "sem-gluten" => "🌾", "sazonais" => "🎃" }.freeze

  has_many :cupcakes, dependent: :restrict_with_error

  validates :name, :slug, presence: true, uniqueness: true

  def icon
    ICONS.fetch(slug, "🧁")
  end
end
