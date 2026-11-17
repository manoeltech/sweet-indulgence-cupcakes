# US09 RNF#2: o cliente escolhe se quer receber avisos sobre os pedidos.
class Profiles::NotificationPreferencesController < ApplicationController
  require_login

  def update
    current_user.update!(notifications_enabled: params[:enabled] == "1")
    redirect_to profile_path, success: "Preferência de notificações atualizada."
  end
end
