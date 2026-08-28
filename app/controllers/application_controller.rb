class ApplicationController < ActionController::Base
  helper ApplicationHelper

  before_action :require_athlete_profile_completion

  helper_method :current_user, :super_admin?, :can_manage_academy?, :can_manage_tournament?, :can_edit_tournament_categories?, :can_register_for_tournament?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id].present?
  end

  def require_user
    redirect_to login_path(return_to: request.fullpath) unless current_user
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

    super_admin? || tournament.managed_by?(current_user)
  end

  def can_edit_tournament_categories?(tournament)
    tournament.categories_editable_by?(current_user)
  end

  def can_register_for_tournament?(tournament)
    return false unless current_user
    return false if current_user.can_organize_tournaments? && !current_user.academy_owner? && !current_user.athlete?

    tournament.accepting_registrations?
  end

  def paginate(scope, per_page: 12)
    page = params[:page].to_i
    page = 1 if page < 1
    total_count = scope.count
    total_pages = (total_count.to_f / per_page).ceil
    total_pages = 1 if total_pages < 1
    page = total_pages if page > total_pages

    [
      scope.limit(per_page).offset((page - 1) * per_page),
      {
        page: page,
        total_pages: total_pages,
        total_count: total_count,
        per_page: per_page
      }
    ]
  end

  def require_athlete_profile_completion
    return unless current_user&.athlete?
    return if current_user.athletes.exists?
    return if controller_name == "athletes" && %w[new create].include?(action_name)
    return if controller_name == "sessions" && action_name == "destroy"
    return if controller_name == "users"

    redirect_to new_athlete_path(profile_setup: true), alert: "Complete your athlete profile to continue."
  end
end
