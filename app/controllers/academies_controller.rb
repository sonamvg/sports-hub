class AcademiesController < ApplicationController
  before_action :require_user, except: %i[index show]
  before_action :set_academy, only: %i[show edit update destroy approve reject]
  before_action :require_academy_manager, only: %i[edit update]
  before_action :require_super_admin, only: %i[destroy approve reject]

  def index
    if current_user&.academy_owner?
      @my_academies = filtered_academies(visible_academies.where(owner: current_user)).order(:created_at, :id)
      @academies = filtered_academies(Academy.approved.where("owner_id IS NULL OR owner_id != ?", current_user.id)).order(:created_at, :id)
    else
      @academies = filtered_academies.order(:created_at, :id)
    end
    @academies, @pagination = paginate(@academies)
  end

  def show
    @athletes = @academy.athletes.order(:first_name, :last_name) if can_manage_academy?(@academy)
    @membership_requests = @academy.academy_membership_requests.pending.includes(:athlete).order(:created_at) if can_manage_academy?(@academy)
    @athlete_registrations = academy_athlete_registrations if can_manage_academy?(@academy)
  end

  def new
    @academy = current_user.owned_academies.build
  end

  def create
    @academy = current_user.owned_academies.build(academy_params)
    @academy.status = super_admin? ? :approved : :pending

    if @academy.save
      redirect_to @academy, notice: academy_created_notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @academy.update(academy_params)
      redirect_to @academy, notice: "Academy updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @academy.destroy
    redirect_to academies_path, notice: "Academy removed."
  end

  def approve
    @academy.update!(status: :approved, reviewed_at: Time.current, rejection_reason: nil)
    @academy.owner&.academy_owner!
    redirect_to @academy, notice: "Academy approved."
  end

  def reject
    @academy.update!(status: :rejected, reviewed_at: Time.current, rejection_reason: params[:rejection_reason].presence)
    redirect_to @academy, notice: "Academy rejected."
  end

  private

  def set_academy
    @academy = Academy.find(params[:id])
  end

  def visible_academies
    return Academy.all if super_admin?
    return Academy.where("status = ? OR owner_id = ?", Academy.statuses[:approved], current_user.id) if current_user

    Academy.approved
  end

  def filtered_academies(academies = visible_academies)
    query = params[:q].to_s.squish.downcase
    return academies if query.blank?

    academies.where(
      "LOWER(name) LIKE :query OR LOWER(COALESCE(city, '')) LIKE :query OR LOWER(COALESCE(state, '')) LIKE :query OR LOWER(COALESCE(country, '')) LIKE :query OR LOWER(COALESCE(registration_number, '')) LIKE :query",
      query: "%#{query}%"
    )
  end

  def require_academy_manager
    raise ActiveRecord::RecordNotFound unless can_manage_academy?(@academy)
  end

  def academy_created_notice
    return "Academy created and approved." if super_admin?

    "Academy submitted for super admin approval."
  end

  def academy_params
    params.require(:academy).permit(
      :name, :registration_number, :city, :state, :country,
      :contact_name, :phone, :email
    )
  end

  def academy_athlete_registrations
    Registration
      .joins(:athlete)
      .includes(:tournament, :tournament_category, :registration_weight_checks, :athlete)
      .where(athletes: { academy_id: @academy.id })
      .order(created_at: :desc)
  end
end
