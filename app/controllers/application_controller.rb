class ApplicationController < ActionController::Base
  add_flash_types :success, :error, :warning
  helper_method :current_user

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::InvalidAuthenticityToken do
    render_error 422, "Formulário expirado", "Recarregue a página e tente novamente."
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def render_not_found
    render_error 404, "Página não encontrada", "O endereço não existe ou o item saiu do cardápio."
  end

  def render_error(status, title, message)
    render "errors/show", status: status, locals: { title: title, message: message }
  end
end
