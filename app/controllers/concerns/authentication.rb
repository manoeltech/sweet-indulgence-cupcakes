# Login por sessão e controle de acesso por papel (cliente, admin, entregador).
module Authentication
  extend ActiveSupport::Concern

  # O que o visitante montou antes de entrar continua depois do login.
  KEPT_ON_SIGN_IN = %w[cart coupon_code].freeze

  included do
    helper_method :current_user, :signed_in?
  end

  class_methods do
    def require_login(**options)
      before_action :require_login, **options
    end

    def require_role(role, **options)
      before_action(**options) { require_role!(role) }
    end
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def signed_in?
    current_user.present?
  end

  def require_login
    return if signed_in?

    redirect_to new_session_path(return_to: request.fullpath), warning: "Entre na sua conta para continuar."
  end

  def require_role!(role)
    return require_login unless signed_in?

    render_error 403, "Acesso negado", "Esta área é restrita." unless current_user.role == role.to_s
  end

  def sign_in(user)
    kept = session.to_hash.slice(*KEPT_ON_SIGN_IN)
    reset_session # evita fixação de sessão
    kept.each { |key, value| session[key] = value }
    session[:user_id] = user.id
    @current_user = user
  end

  def sign_out
    reset_session
    @current_user = nil
  end

  # Só aceita caminhos internos, para evitar open redirect.
  def safe_return_to
    path = params[:return_to].to_s
    path if path.start_with?("/") && !path.start_with?("//")
  end

  def home_path_for(_user)
    root_path
  end
end
