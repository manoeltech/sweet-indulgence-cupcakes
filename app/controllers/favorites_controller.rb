# US05: lista de cupcakes favoritos do cliente.
class FavoritesController < ApplicationController
  require_role :customer

  def index
    @cupcakes = current_user.favorite_cupcakes.active.includes(:category).order("favorites.created_at DESC")
  end
end
