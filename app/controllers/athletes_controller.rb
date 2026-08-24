class AthletesController < ApplicationController
  before_action :require_user
  before_action :set_athlete, only: %i[show edit update destroy]
  before_action :set_available_academies, only: %i[new create edit update]

  def index
    @athletes = Athlete.none
    @athletes = current_user.athletes.includes(:academy).order(:first_name, :last_name) if current_user
    @athletes = Athlete.includes(:academy, :user).order(:first_name, :last_name) if super_admin?
  end

  def show; end

  def new
    @athlete = current_user.athletes.build
    @return_to = safe_return_path(params[:return_to])
  end

  def create
    @athlete = current_user.athletes.build(athlete_params)
    @return_to = safe_return_path(params[:return_to])

    if @athlete.save
      redirect_to(@return_to.presence || @athlete, notice: "Athlete profile created.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @return_to = safe_return_path(params[:return_to])

    if @athlete.update(athlete_params)
      redirect_to(@return_to.presence || @athlete, notice: "Athlete profile updated.")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @athlete.destroy
    redirect_to athletes_path, notice: "Athlete profile removed."
  end

  private

  def set_athlete
    @athlete = current_user.athletes.find(params[:id])
  end

  def athlete_params
    params.require(:athlete).permit(
      :academy_id, :first_name, :last_name, :date_of_birth, :gender,
      :belt, :weight, :association_id, :city, :state, :country
    )
  end

  def set_available_academies
    @available_academies = Academy.approved.order(:name)
  end

  def safe_return_path(path)
    return if path.blank?

    path.to_s.start_with?("/") && !path.to_s.start_with?("//") ? path : nil
  end
end
