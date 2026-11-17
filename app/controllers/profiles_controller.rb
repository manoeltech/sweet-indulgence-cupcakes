class ProfilesController < ApplicationController
  require_login

  def show
    @user = current_user
    @address = Address.new
  end
end
