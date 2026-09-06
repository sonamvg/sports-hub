class PasswordResetsController < ApplicationController
  before_action :redirect_authenticated_user, only: %i[new create]
  before_action :set_user_by_token, only: %i[edit update]

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.downcase.squish)
    user&.send_password_reset_email

    redirect_to login_path, notice: "If that email is registered, we've sent instructions to reset the password."
  end

  def edit; end

  def update
    if @user.update(password_params)
      redirect_to login_path, notice: "Password updated. Please sign in."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def redirect_authenticated_user
    return unless current_user

    redirect_to tournaments_path, alert: "You are already signed in."
  end

  def set_user_by_token
    @user = User.find_by_token_for(:password_reset, params[:token])
    redirect_to new_password_reset_path, alert: "That password reset link is invalid or has expired." unless @user
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
