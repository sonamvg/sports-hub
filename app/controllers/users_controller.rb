class UsersController < ApplicationController
  def new
    @account_type = account_type_param
    @user = User.new(role: signup_role, email: invited_email_param)
    set_available_academies
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
      set_available_academies
      render :new, status: :unprocessable_entity
    end
  end

  private

  def account_type_param
    return "organizer" if params[:account_type] == "organizer"
    return "academy_owner" if params[:account_type] == "academy_owner"

    "athlete"
  end

  def invited_email_param
    params[:invited_email].to_s.downcase.squish.presence
  end

  def signup_role
    case @account_type
    when "organizer" then :organizer
    when "academy_owner" then :academy_owner
    else :athlete
    end
  end

  def after_signup_path
    return organizers_path if @account_type == "organizer"
    return new_athlete_path(profile_setup: true, return_to: safe_return_path(params[:return_to])) if @account_type == "athlete"

    safe_return_path(params[:return_to]) || tournaments_path
  end

  def signup_notice
    return "Organizer account created and sent to super admin for verification." if @account_type == "organizer"

    return "Athlete account created. Complete your profile to continue." if @account_type == "athlete"

    "Account created."
  end

  def set_available_academies
    @available_academies = Academy.approved.order(:name)
  end

  def safe_return_path(path)
    return if path.blank?

    path.to_s.start_with?("/") && !path.to_s.start_with?("//") ? path : nil
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :phone, :profile_photo_url, :organizer_designation,
      :organizer_academy_id, :identity_document, :password, :password_confirmation
    )
  end
end
