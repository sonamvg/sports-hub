class TournamentsController < ApplicationController
  before_action :require_user, except: %i[index show]
  before_action :set_tournament, only: %i[show edit update draw]
  before_action :require_tournament_manager, only: %i[edit update draw]

  def index
    @tournaments = Tournament.order(:start_date)
  end

  def new
    @tournament = Tournament.new(status: :draft)
  end

  def create
    @tournament = Tournament.new(tournament_params)
    @tournament.organizer = current_user

    if @tournament.save
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
    if @tournament.update(tournament_params)
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

  def tournament_params
    params.require(:tournament).permit(
      :name, :slug, :description, :venue, :city, :state, :start_date, :end_date,
      :registration_opens_at, :registration_closes_at, :status
    )
  end
end
