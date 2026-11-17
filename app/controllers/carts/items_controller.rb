# US04: adicionar, alterar a quantidade e remover itens do carrinho.
class Carts::ItemsController < ApplicationController
  rescue_from BusinessRuleError do |error|
    redirect_back fallback_location: cart_path, error: error.message
  end

  def create
    cupcake = Cupcake.active.find(params[:cupcake_id])
    cart.add(cupcake, params.fetch(:quantity, 1))
    redirect_to cart_path, success: "#{cupcake.name} adicionado ao carrinho."
  end

  def update
    cart.change(cupcake, params[:step] == "up" ? 1 : -1)
    if cart.include?(cupcake)
      redirect_to cart_path
    else
      redirect_to cart_path, success: "#{cupcake.name} removido do carrinho."
    end
  end

  def destroy
    cart.remove(cupcake)
    redirect_to cart_path, success: "#{cupcake.name} removido do carrinho."
  end

  private

  def cupcake
    @cupcake ||= Cupcake.find(params[:id])
  end
end
