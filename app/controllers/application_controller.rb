class ApplicationController < ActionController::Base
  include Authentication
  include CurrentCart

  add_flash_types :success, :error, :warning

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::InvalidAuthenticityToken do
    render_error 422, "Formulário expirado", "Recarregue a página e tente novamente."
  end

  private

  def render_not_found
    render_error 404, "Página não encontrada", "O endereço não existe ou o item saiu do cardápio."
  end

  def render_error(status, title, message)
    render "errors/show", status: status, locals: { title: title, message: message }
  end
end
