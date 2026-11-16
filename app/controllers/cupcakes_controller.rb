# Vitrine: US01 (lista), US02 (filtro e busca) e US03 (nutricional e alérgenos).
class CupcakesController < ApplicationController
  def index
    @category_slug = params[:categoria].presence
    @query = params[:q].to_s.strip
    @categories = Category.order(:name)
    @cupcakes = Cupcake.storefront(category_slug: @category_slug, query: @query)
  end

  def show
    @cupcake = Cupcake.active.find(params[:id])
    @reviews = @cupcake.reviews.includes(:user).order(created_at: :desc).limit(5)
  end
end
