class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.authenticate_by(email: params[:email].to_s.strip.downcase, password: params[:password].to_s)
    if user
      sign_in(user)
      redirect_to safe_return_to || home_path_for(user)
    else
      flash.now[:error] = "E-mail ou senha incorretos."
      render :new, status: :unauthorized
    end
  end

  def destroy
    sign_out
    redirect_to root_path, success: "Você saiu da sua conta."
  end
end
