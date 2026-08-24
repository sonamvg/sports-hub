class ApplicationController < ActionController::Base
  helper_method :current_user, :demo_organizer, :super_admin?, :can_manage_academy?, :can_manage_tournament?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id].present?
  end

  def demo_organizer
    @demo_organizer ||= User.find_by(email: "organizer@example.com")
  end

  def require_user
    redirect_to login_path(return_to: request.fullpath), alert: "Please sign in before continuing." unless current_user
  end

  def require_super_admin
    raise ActiveRecord::RecordNotFound unless super_admin?
  end

  def super_admin?
    current_user&.super_admin?
  end

  def can_manage_academy?(academy)
    return false unless current_user

    super_admin? || academy.owner_id == current_user.id
  end

  def can_manage_tournament?(tournament)
    return false unless current_user

    super_admin? || tournament.organizer_id == current_user.id
  end
end
