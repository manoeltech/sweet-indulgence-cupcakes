class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :cupcake

  validates :cupcake_id, uniqueness: { scope: :user_id }

  # US05: o coração alterna entre favoritar e desfavoritar.
  def self.toggle!(user, cupcake)
    favorite = find_by(user: user, cupcake: cupcake)
    if favorite
      favorite.destroy!
      false
    else
      create!(user: user, cupcake: cupcake)
      true
    end
  end
end
