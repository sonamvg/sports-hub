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
      redirect_to safe_return_path(params[:return_to]) || tournaments_path, notice: "Signed in as #{user.name}."
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
end
