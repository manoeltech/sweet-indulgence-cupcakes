# US05: o coração alterna entre favoritar e desfavoritar.
class Cupcakes::FavoritesController < ApplicationController
  require_role :customer

  def create
    cupcake = Cupcake.active.find(params[:cupcake_id])
    added = Favorite.toggle!(current_user, cupcake)
    message = added ? "#{cupcake.name} foi para os favoritos." : "#{cupcake.name} saiu dos favoritos."
    redirect_to safe_return_to || cupcake_path(cupcake), success: message
  end
end
