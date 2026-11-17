# US12: reposição rápida do estoque pela lista de produtos.
class Admin::Cupcakes::StocksController < Admin::BaseController
  def update
    cupcake = Cupcake.find(params[:cupcake_id])
    if cupcake.update(stock: params[:stock])
      redirect_to admin_cupcakes_path, success: "Estoque de #{cupcake.name} atualizado para #{cupcake.stock}."
    else
      redirect_to admin_cupcakes_path, error: "Informe um estoque inteiro igual ou maior que zero."
    end
  end
end
