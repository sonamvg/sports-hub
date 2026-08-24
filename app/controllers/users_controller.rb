class UsersController < ApplicationController
  def new
    @account_type = account_type_param
    @user = User.new(role: signup_role)
  end

  def create
    @user = User.new(user_params)
    @account_type = account_type_param
    @user.role = signup_role

    if @user.save
      reset_session
      session[:user_id] = @user.id
      redirect_to safe_return_path(params[:return_to]) || tournaments_path, notice: "Account created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def account_type_param
    return "organizer" if params[:account_type] == "organizer"
    return "academy_owner" if params[:account_type] == "academy_owner"

    "athlete"
  end

  def signup_role
    case @account_type
    when "organizer" then :organizer
    when "academy_owner" then :academy_owner
    else :parent
    end
  end

  def safe_return_path(path)
    return if path.blank?

    path.to_s.start_with?("/") && !path.to_s.start_with?("//") ? path : nil
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation)
  end
end
