class UsersController < ApplicationController
  def new
    @account_type = account_type_param
    @user = User.new(role: signup_role)
  end

  def create
    @user = User.new(user_params)
    @account_type = account_type_param
    @user.role = signup_role
    @user.organizer_status = :pending if @account_type == "organizer"

    if @user.save
      reset_session
      session[:user_id] = @user.id
      redirect_to after_signup_path, notice: signup_notice
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

  def after_signup_path
    return organizers_path if @account_type == "organizer"

    safe_return_path(params[:return_to]) || tournaments_path
  end

  def signup_notice
    return "Organizer account created and sent to super admin for verification." if @account_type == "organizer"

    "Account created."
  end

  def safe_return_path(path)
    return if path.blank?

    path.to_s.start_with?("/") && !path.to_s.start_with?("//") ? path : nil
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone, :profile_photo_url, :password, :password_confirmation)
  end
end
