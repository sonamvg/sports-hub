class TournamentsController < ApplicationController
  before_action :require_user, except: %i[index show]
  before_action :require_verified_organizer, only: %i[new create]
  before_action :set_tournament, only: %i[show edit update draw]
  before_action :require_tournament_manager, only: %i[edit update draw]
  before_action :set_available_organizers, only: %i[new create edit update]

  def index
    @tournaments = Tournament.order(:start_date)
  end

  def new
    @tournament = Tournament.new(status: :draft, time_zone: Time.zone.name, currency: "INR", category_generation_method: "Auto-generate from eligibility rules")
  end

  def create
    @tournament = Tournament.new(tournament_params)
    @tournament.organizer = current_user
    apply_submit_intent(@tournament)

    if @tournament.save
      sync_tournament_organizers
      redirect_to @tournament, notice: "Tournament created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @categories = @tournament.tournament_categories.order(:name)
    @athletes = current_user ? current_user.athletes.includes(:academy).order(:first_name, :last_name) : Athlete.none
    @registrations_by_athlete_id = @tournament.registrations.includes(:tournament_category).index_by(&:athlete_id)
  end

  def edit; end

  def draw; end

  def update
    @tournament.assign_attributes(tournament_params)
    apply_submit_intent(@tournament)
    if @tournament.save
      sync_tournament_organizers
      redirect_to @tournament, notice: "Tournament updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_tournament
    @tournament = Tournament.includes(:tournament_categories).find(params[:id])
  end

  def require_tournament_manager
    raise ActiveRecord::RecordNotFound unless can_manage_tournament?(@tournament)
  end

  def require_verified_organizer
    return if current_user&.can_organize_tournaments?

    redirect_to organizers_path, alert: "Super admin verification is required before creating tournaments."
  end

  def set_available_organizers
    @available_organizers = User.verified_organizers.order(:name)
  end

  def sync_tournament_organizers
    selected_ids = Array(params.dig(:tournament, :organizer_user_ids)).reject(&:blank?).map(&:to_i)
    selected_ids << @tournament.organizer_id
    verified_ids = User.verified_organizers.where(id: selected_ids).pluck(:id)
    verified_ids << @tournament.organizer_id
    verified_ids.uniq!

    @tournament.tournament_organizers.where.not(user_id: verified_ids).destroy_all

    verified_ids.each do |user_id|
      membership = @tournament.tournament_organizers.find_or_initialize_by(user_id: user_id)
      membership.role = user_id == @tournament.organizer_id ? :super_organizer : :collaborator
      membership.added_by ||= current_user
      membership.save!
    end
  end

  def tournament_params
    params.require(:tournament).permit(
      :name, :slug, :description, :venue, :city, :state, :start_date, :end_date,
      :registration_opens_at, :registration_closes_at, :status, :website_url, :logo_url,
      :tournament_level, :organizing_organization, :time_zone, :primary_contact_name,
      :primary_contact_email, :primary_contact_phone, :competition_formats,
      :eligibility_summary, :category_generation_method, :registration_capacity,
      :registration_fee, :currency, :required_documents, :refund_policy, :banner_image_url
    )
  end

  def apply_submit_intent(tournament)
    tournament.status = :draft if params[:commit] == "Save as Draft"
    tournament.status = :scheduled if params[:commit] == "Publish" && tournament.draft?
  end
end
