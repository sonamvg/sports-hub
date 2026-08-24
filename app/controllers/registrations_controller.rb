class RegistrationsController < ApplicationController
  before_action :require_user
  before_action :set_tournament
  before_action :ensure_registration_open, only: %i[new create]

  def index
    @registrations = @tournament.registrations.where(athlete: current_user.athletes).includes(:athlete, :tournament_category)
  end

  def new
    @registration = @tournament.registrations.build(
      athlete_id: params[:athlete_id],
      tournament_category_id: params[:category_id]
    )
    @athletes = current_user.athletes.order(:first_name, :last_name)
    @categories = @tournament.tournament_categories.order(:name)
  end

  def create
    @registration = @tournament.registrations.build(registration_params)
    @registration.athlete = current_user.athletes.find_by(id: registration_params[:athlete_id])

    if @registration.save
      redirect_to tournament_registrations_path(@tournament), notice: "Registration submitted for organizer approval."
    else
      @athletes = current_user.athletes.order(:first_name, :last_name)
      @categories = @tournament.tournament_categories.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def ensure_registration_open
    return if @tournament.accepting_registrations?

    redirect_to @tournament, alert: "Registration is not open for this tournament."
  end

  def registration_params
    params.require(:registration).permit(:athlete_id, :tournament_category_id, :registered_weight)
  end
end
