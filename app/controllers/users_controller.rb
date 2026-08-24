class UsersController < ApplicationController
  def new
    @user = User.new(role: :parent)
  end

  def create
    @user = User.new(user_params)
    @user.role = :parent

    if @user.save
      reset_session
      session[:user_id] = @user.id
      redirect_to tournaments_path, notice: "Account created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation)
  end
end
