# Área do administrador: só usuários com papel admin.
class Admin::BaseController < ApplicationController
  require_role :admin

  rescue_from BusinessRuleError do |error|
    redirect_back fallback_location: admin_root_path, error: error.message
  end
end
