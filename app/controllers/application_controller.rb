class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper ApplicationHelper

  # Idle timeout: a signed-in user who sends no request for this long is
  # signed out automatically on their next request. The session's
  # `last_seen_at` slides forward on every authenticated request, so this is
  # inactivity time, not a hard session lifetime.
  SESSION_TIMEOUT = 30.minutes

  before_action :enforce_session_timeout
  before_action :enforce_session_fingerprint
  before_action :require_athlete_profile_completion

  helper_method :current_user, :super_admin?, :can_manage_academy?, :can_manage_tournament?, :can_register_for_tournament?, :athlete_home_path, :session_timeout_seconds

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id].present?
  end

  def enforce_session_timeout
    return if session[:user_id].blank?

    last_seen_at = session[:last_seen_at]
    if last_seen_at.present? && Time.current.to_i - last_seen_at > SESSION_TIMEOUT
      reset_session
      redirect_to login_path, alert: "You've been signed out due to inactivity. Please sign in again."
      return
    end

    session[:last_seen_at] = Time.current.to_i
  end

  def session_timeout_seconds
    SESSION_TIMEOUT.to_i
  end

  # Binds the session to the browser it was issued in. The session cookie
  # itself is scoped per-browser-profile already (a real incognito window has
  # its own separate cookie jar and can never read another window's session
  # cookie) — this is a second, independent check on top of that: if a
  # session cookie is somehow replayed from a different client (a copied
  # cookie, a proxy, a compromised device), the User-Agent it arrives with
  # won't match the one recorded at login, and the session is discarded.
  def enforce_session_fingerprint
    return if session[:user_id].blank?

    if session[:fingerprint].present? && session[:fingerprint] != session_fingerprint
      reset_session
      redirect_to login_path, alert: "Your session could not be verified for this browser. Please sign in again."
      return
    end

    session[:fingerprint] ||= session_fingerprint
  end

  def session_fingerprint
    Digest::SHA256.hexdigest(request.user_agent.to_s)
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

  def athlete_home_path
    return athletes_path unless current_user&.athlete?

    athlete = current_user.athletes.order(:created_at).first
    athlete ? athlete_path(athlete) : new_athlete_path(profile_setup: true)
  end

  def require_athlete_profile_completion
    return unless current_user&.athlete?
    return if current_user.athletes.exists?
    return if controller_name == "athletes" && %w[new create].include?(action_name)
    return if controller_name == "home" && action_name == "terms"
    return if controller_name == "sessions" && action_name == "destroy"
    return if controller_name == "users"

    redirect_to new_athlete_path(profile_setup: true), alert: "Complete your athlete profile to continue."
  end
end
