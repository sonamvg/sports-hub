class AthletesController < ApplicationController
  before_action :require_user
  before_action :redirect_athlete_index_to_profile, only: %i[index]
  before_action :prevent_extra_athlete_profile, only: %i[new create]
  before_action :set_athlete, only: %i[show edit update destroy]
  before_action :set_available_academies, only: %i[new create edit update]

  def index
    @organizer_restricted_index = current_user.can_organize_tournaments? && !super_admin? && current_user.owned_academies.none?
    @athletes = @organizer_restricted_index ? Athlete.none : filtered_athletes.includes(:academy).order(:first_name, :last_name)
    @athletes = @athletes.includes(:user) if super_admin?
    @athletes, @pagination = paginate(@athletes)
  end

  def show; end

  def new
    @athlete = current_user.athletes.build
    assign_name_from_user(@athlete) if params[:profile_setup].present?
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

  def edit
    @return_to = athlete_path(@athlete) if current_user.athlete?
  end

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

  def redirect_athlete_index_to_profile
    return unless current_user.athlete?

    redirect_to athlete_home_path
  end

  def prevent_extra_athlete_profile
    return unless current_user.athlete?
    return unless current_user.athletes.exists?

    redirect_to athlete_home_path, alert: "Athlete accounts can manage only their own profile."
  end

  def set_athlete
    @athlete = visible_athletes.find(params[:id])
  end

  def visible_athletes
    return Athlete.all if super_admin?

    owned_academy_ids = current_user.owned_academies.approved.select(:id)
    athlete_ids = Athlete.where(user_id: current_user.id).pluck(:id)
    athlete_ids += Athlete.where(academy_id: owned_academy_ids).pluck(:id)
    athlete_ids += registered_athletes_for_managed_tournaments.pluck(:id) if current_user.can_organize_tournaments?

    Athlete.where(id: athlete_ids.uniq)
  end

  def registered_athletes_for_managed_tournaments
    managed_tournament_ids = Tournament
      .left_joins(:tournament_organizers)
      .where("tournaments.organizer_id = :user_id OR tournament_organizers.user_id = :user_id", user_id: current_user.id)
      .select(:id)

    Athlete.joins(:registrations).where(registrations: { tournament_id: managed_tournament_ids })
  end

  def filtered_athletes
    athletes = visible_athletes
    query = params[:q].to_s.squish.downcase
    if query.present?
      athletes = athletes.left_joins(:academy).where(
        "LOWER(athletes.first_name) LIKE :query OR LOWER(athletes.last_name) LIKE :query OR LOWER(CONCAT(athletes.first_name, ' ', athletes.last_name)) LIKE :query OR LOWER(COALESCE(athletes.association_id, '')) LIKE :query OR LOWER(COALESCE(academies.name, '')) LIKE :query",
        query: "%#{query}%"
      )
    end

    athletes = athletes.where(belt: params[:belt]) if params[:belt].present?
    athletes = athletes.where("weight >= ?", params[:weight_min].to_d) if params[:weight_min].present?
    athletes = athletes.where("weight <= ?", params[:weight_max].to_d) if params[:weight_max].present?
    athletes = athletes.where("date_of_birth <= ?", params[:age_min].to_i.years.ago.to_date) if params[:age_min].present?
    athletes = athletes.where("date_of_birth >= ?", (params[:age_max].to_i + 1).years.ago.to_date + 1.day) if params[:age_max].present?
    athletes
  end

  def athlete_params
    params.require(:athlete).permit(
      :academy_id, :first_name, :last_name, :date_of_birth, :gender,
      :belt, :weight, :association_id, :city, :state, :country,
      :contact_number, :blood_group, :emergency_contact_name,
      :emergency_contact_phone, :address, :government_id_document_type,
      :profile_photo, :identity_document
    )
  end

  def assign_name_from_user(athlete)
    names = current_user.name.to_s.split
    athlete.first_name ||= names.first
    athlete.last_name ||= names.drop(1).join(" ").presence
    athlete.contact_number ||= current_user.phone
  end

  def set_available_academies
    @available_academies = Academy.approved.order(:name)
  end

  def safe_return_path(path)
    return if path.blank?

    path.to_s.start_with?("/") && !path.to_s.start_with?("//") ? path : nil
  end
end
