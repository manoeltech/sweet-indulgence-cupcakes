class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.merge(role: :customer))
    if @user.save
      sign_in(@user)
      redirect_to safe_return_to || root_path, success: "Bem-vindo(a), #{@user.first_name}!"
    else
      flash.now[:error] = @user.errors.map(&:message).to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [ :name, :email, :phone, :password, :password_confirmation ])
  end
end
