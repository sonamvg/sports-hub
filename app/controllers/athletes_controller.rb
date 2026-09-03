require "securerandom"

class AthletesController < ApplicationController
  before_action :require_user
  before_action :redirect_athlete_index_to_profile, only: %i[index]
  before_action :prevent_extra_athlete_profile, only: %i[new create]
  before_action :set_athlete, only: %i[show edit update destroy]
  before_action :require_athlete_editor, only: %i[edit update]
  before_action :set_available_academies, only: %i[new create edit update]

  def index
    @organizer_restricted_index = current_user.can_organize_tournaments? && !super_admin? && current_user.owned_academies.none?
    @athletes = @organizer_restricted_index ? Athlete.none : filtered_athletes.includes(:academy).order(:first_name, :last_name)
    @athletes = @athletes.includes(:user) if super_admin?
    @athletes, @pagination = paginate(@athletes)
  end

  def show
    @return_to = safe_return_path(params[:return_to])
    registrations = @athlete.registrations.includes(:tournament, :tournament_category, :registration_weight_checks)
    @upcoming_registrations = registrations.select { |registration| registration.tournament.end_date >= Date.current }.sort_by { |registration| [registration.tournament.start_date, registration.created_at] }
    @previous_registrations = registrations.select { |registration| registration.tournament.end_date < Date.current }.sort_by { |registration| [registration.tournament.start_date, registration.created_at] }.reverse
  end

  def new
    @athlete = current_user.academy_owner? ? Athlete.new(academy_id: academy_owner_default_academy_id) : current_user.athletes.build
    assign_name_from_user(@athlete) if params[:profile_setup].present?
    @return_to = safe_return_path(params[:return_to])
  end

  def create
    return create_academy_owned_athlete if current_user.academy_owner?

    @athlete = current_user.athletes.build(athlete_params)
    @athlete.require_consent = true
    @return_to = safe_return_path(params[:return_to])
    requested_academy_id = academy_request_id

    if @athlete.save
      create_academy_request_if_needed(@athlete, requested_academy_id)
      sync_super_admin_unregistered_academy_notification(@athlete)
      redirect_to(@return_to.presence || @athlete, notice: athlete_saved_notice(requested_academy_id, created: true))
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @return_to = athlete_path(@athlete) if current_user.athlete?
  end

  def update
    @return_to = safe_return_path(params[:return_to])
    requested_academy_id = academy_request_id

    if @athlete.update(athlete_params)
      create_academy_request_if_needed(@athlete, requested_academy_id)
      sync_super_admin_unregistered_academy_notification(@athlete)
      redirect_to(@return_to.presence || @athlete, notice: athlete_saved_notice(requested_academy_id, created: false))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if super_admin?
      @athlete.destroy
      redirect_to athletes_path, notice: "Athlete profile removed."
    elsif current_user.academy_owner? && can_manage_academy?(@athlete.academy)
      academy = @athlete.academy
      @athlete.academy_membership_requests.where(academy: academy, status: %i[pending approved]).update_all(status: AcademyMembershipRequest.statuses[:rejected], reviewed_by_id: current_user.id, reviewed_at: Time.current, updated_at: Time.current)
      @athlete.update!(academy: nil, external_academy_name: nil)
      AthleteAccountMailer.with(athlete: @athlete, academy: academy).academy_removed.deliver_later
      redirect_to academy_path(academy), notice: "Athlete removed from academy."
    elsif @athlete.user_id == current_user.id
      @athlete.destroy
      redirect_to athletes_path, notice: "Athlete profile removed."
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  private

  def create_academy_owned_athlete
    @athlete = Athlete.new(athlete_params)
    @athlete.require_consent = true
    @athlete.account_email = athlete_account_email
    @return_to = safe_return_path(params[:return_to])
    validate_academy_owned_athlete

    if @athlete.errors.any?
      render :new, status: :unprocessable_entity
      return
    end

    password = SecureRandom.alphanumeric(12)
    academy = @athlete.academy

    ActiveRecord::Base.transaction do
      user = User.create!(
        name: @athlete.full_name,
        email: @athlete.account_email,
        role: :athlete,
        phone: @athlete.contact_number,
        password: password,
        password_confirmation: password
      )
      @athlete.user = user
      @athlete.save!
    end

    AthleteAccountMailer.with(athlete: @athlete, academy: academy, password: password).academy_created_account.deliver_later
    redirect_to academy_path(academy), notice: "Athlete account created and sign-in details sent."
  rescue ActiveRecord::RecordInvalid => error
    @athlete.errors.merge!(error.record.errors)
    render :new, status: :unprocessable_entity
  end

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

  def require_athlete_editor
    raise ActiveRecord::RecordNotFound unless super_admin? || @athlete.user_id == current_user.id
  end

  def visible_athletes
    return Athlete.all if super_admin?

    owned_academy_ids = current_user.owned_academies.approved.select(:id)
    athlete_ids = Athlete.where(user_id: current_user.id).pluck(:id)
    athlete_ids += Athlete.where(academy_id: owned_academy_ids).pluck(:id)
    athlete_ids += Athlete.joins(:academy_membership_requests).where(academy_membership_requests: { academy_id: owned_academy_ids, status: AcademyMembershipRequest.statuses[:pending] }).pluck(:id)
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
    permitted = params.require(:athlete).permit(
      :academy_id, :first_name, :last_name, :date_of_birth, :gender,
      :belt, :weight, :association_id, :city, :state, :country,
      :contact_number, :blood_group, :emergency_contact_name,
      :emergency_contact_phone, :address, :government_id_document_type,
      :external_academy_name, :profile_photo, :identity_document
    )
    permitted.merge!(
      terms_accepted: params.dig(:athlete, :terms_accepted),
      data_sharing_consent: params.dig(:athlete, :data_sharing_consent)
    )
    return permitted unless athlete_account_self_service?

    academy_choice = params.dig(:athlete, :academy_id).to_s
    permitted.delete(:association_id)
    if academy_choice.blank?
      permitted[:academy_id] = nil
      permitted[:external_academy_name] = nil
    else
      permitted.delete(:academy_id)
      permitted[:external_academy_name] = nil unless academy_choice == "other"
    end
    permitted
  end

  def assign_name_from_user(athlete)
    names = current_user.name.to_s.split
    athlete.first_name ||= names.first
    athlete.last_name ||= names.drop(1).join(" ").presence
    athlete.contact_number ||= current_user.phone
  end

  def set_available_academies
    @available_academies = if current_user.academy_owner? && !super_admin?
      current_user.owned_academies.approved.order(:name)
    else
      Academy.approved.order(:name)
    end
  end

  def academy_request_id
    return unless athlete_account_self_service?

    academy_id = params.dig(:athlete, :academy_id).to_s
    return if academy_id == "other"

    academy_id.presence
  end

  def athlete_account_self_service?
    current_user.athlete?
  end

  def create_academy_request_if_needed(athlete, academy_id)
    return if academy_id.blank?

    academy = Academy.approved.find_by(id: academy_id)
    return unless academy
    return if athlete.academy_id == academy.id

    athlete.academy_membership_requests.pending.where.not(academy: academy).update_all(status: AcademyMembershipRequest.statuses[:rejected], reviewed_at: Time.current, updated_at: Time.current)
    membership_request = athlete.academy_membership_requests.find_or_initialize_by(academy: academy, status: :pending)
    membership_request.requested_by ||= current_user
    membership_request.dismissed_at = nil
    membership_request.save!
  end

  def sync_super_admin_unregistered_academy_notification(athlete)
    return unless athlete_account_self_service?

    if athlete.academy_id.present? || athlete.external_academy_name.blank?
      SuperAdminNotification.pending.unregistered_academy_athlete.where(notifiable: athlete).find_each(&:dismiss!)
      return
    end

    SuperAdminNotification.notify!(
      kind: :unregistered_academy_athlete,
      notifiable: athlete,
      actor: current_user,
      message: "#{athlete.full_name} listed #{athlete.external_academy_name} as an unregistered academy."
    )
  end

  def athlete_saved_notice(academy_id, created:)
    return "Academy join request sent to the academy owner." if academy_id.present?

    created ? "Athlete profile created." : "Athlete profile updated."
  end

  def safe_return_path(path)
    return if path.blank?

    path.to_s.start_with?("/") && !path.to_s.start_with?("//") ? path : nil
  end

  def academy_owner_default_academy_id
    academy_id = params[:academy_id].presence
    return academy_id if current_user.owned_academies.approved.exists?(id: academy_id)

    current_user.owned_academies.approved.order(:name).first&.id
  end

  def athlete_account_email
    params.dig(:athlete, :account_email).to_s.downcase.squish
  end

  def validate_academy_owned_athlete
    @athlete.errors.add(:academy, "must be one of your approved academies") unless @athlete.academy.present? && can_manage_academy?(@athlete.academy) && @athlete.academy.approved?
    @athlete.errors.add(:account_email, "must be provided for the athlete account") if @athlete.account_email.blank?
    @athlete.errors.add(:account_email, "is already used by another account") if @athlete.account_email.present? && User.exists?(email: @athlete.account_email)
  end
end
