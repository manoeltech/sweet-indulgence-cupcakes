# US11 / CU02 – Gerenciar catálogo.
class Admin::CupcakesController < Admin::BaseController
  before_action :set_cupcake, only: %i[edit update destroy]

  def index
    @cupcakes = Cupcake.includes(:category).order(active: :desc, name: :asc)
  end

  def new
    @cupcake = Cupcake.new
  end

  def create
    @cupcake = Cupcake.new(cupcake_params)
    save_or_render :new
  end

  def edit
  end

  def update
    @cupcake.assign_attributes(cupcake_params)
    save_or_render :edit
  end

  # CU02 passo 5: só remove com o nome exato (CU02-B); o cupcake sai do cardápio, mas fica no histórico.
  def destroy
    @cupcake.remove_from_menu!(params[:confirmation])
    redirect_to admin_cupcakes_path, success: "#{@cupcake.name} saiu do cardápio."
  rescue BusinessRuleError => error
    redirect_to admin_cupcakes_path, warning: error.message
  end

  private

  def set_cupcake
    @cupcake = Cupcake.find(params[:id])
  end

  # CU02-A: dados inválidos mostram o formulário de novo, com o que foi digitado.
  def save_or_render(template)
    if @cupcake.save
      redirect_to admin_cupcakes_path, success: "#{@cupcake.name} salvo."
    else
      render template, status: :unprocessable_entity
    end
  end

  def cupcake_params
    params.expect(cupcake: [ :name, :category_id, :description, :ingredients, :price, :stock, :min_stock,
                             :calories, :fat_grams, :sugar_grams, :allergens, :color, :active, :photo_upload ])
  end
end
