class SessionsController < ApplicationController
  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.downcase.squish)

    if params[:email].blank? || params[:password].blank?
      flash.now[:alert] = "Please sign in before continuing."
      render :new, status: :unprocessable_entity
    elsif user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      redirect_to safe_return_path(params[:return_to]) || default_after_login_path(user), notice: "Signed in as #{user.name}."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out."
  end

  private

  def safe_return_path(path)
    return if path.blank?

    path.to_s.start_with?("/") && !path.to_s.start_with?("//") ? path : nil
  end

  def default_after_login_path(user)
    return athlete_path(user.athletes.order(:created_at).first) if user.athlete? && user.athletes.exists?
    return new_athlete_path(profile_setup: true) if user.athlete?
    return academies_path if user.academy_owner?

    tournaments_path
  end
end
