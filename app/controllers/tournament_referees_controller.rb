class TournamentRefereesController < ApplicationController
  before_action :require_user
  before_action :set_tournament
  before_action :require_tournament_manager
  before_action :set_referee, only: %i[show edit update destroy]

  def index
    @referees = @tournament.tournament_referees.with_attached_photo.order(:name)
  end

  def show; end

  def new
    @referee = @tournament.tournament_referees.build
  end

  def create
    @referee = @tournament.tournament_referees.build(referee_params)

    if @referee.save
      redirect_to tournament_tournament_referees_path(@tournament), notice: "Referee added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @referee.update(referee_params)
      redirect_to tournament_tournament_referee_path(@tournament, @referee), notice: "Referee updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @referee.destroy
    redirect_to tournament_tournament_referees_path(@tournament), notice: "Referee removed."
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def set_referee
    @referee = @tournament.tournament_referees.find(params[:id])
  end

  def require_tournament_manager
    raise ActiveRecord::RecordNotFound unless can_manage_tournament?(@tournament)
  end

  def referee_params
    params.require(:tournament_referee).permit(
      :name, :email, :phone, :role, :qualification,
      :certification_id, :affiliation, :notes, :photo
    )
  end
end
