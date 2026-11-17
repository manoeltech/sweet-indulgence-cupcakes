# Ilustração vetorial gerada a partir da cor da cobertura: leve para o 4G (US01 RNF#1).
class Cupcakes::ImagesController < ApplicationController
  def show
    @cupcake = Cupcake.find(params[:cupcake_id])
    expires_in 1.day, public: true
    render formats: :svg
  end
end
