class RegistrationsController < ApplicationController
  before_action :require_user
  before_action :set_tournament
  before_action :ensure_registration_open, only: %i[new create]

  def index
    @registrations = @tournament.registrations.where(athlete: manageable_athletes).includes(:athlete, :tournament_category).order(status_sort_sql, created_at: :desc)
  end

  def new
    @registration = @tournament.registrations.build(
      athlete_id: params[:athlete_id] || manageable_athletes.order(:first_name, :last_name).first&.id
    )
    set_registration_collections
    @selected_category_ids = selected_category_ids
  end

  def create
    @registration = @tournament.registrations.build
    @athlete = manageable_athletes.find_by(id: registration_params[:athlete_id])
    @selected_category_ids = Array(registration_params[:tournament_category_ids]).reject(&:blank?)
    submit_registration = params[:commit] != "Save and pay later"

    if save_category_registrations(submit_registration: submit_registration)
      notice = submit_registration ? "Registration submitted to tournament organizers for approval." : "Selection saved. Upload payment receipt when you are ready to submit."
      redirect_to tournament_registrations_path(@tournament), notice: notice
    else
      set_registration_collections
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def ensure_registration_open
    return if @tournament.accepting_registrations?
    return if @tournament.late_registration_allowed_for?(current_user)

    redirect_to @tournament, alert: "Registration is not open for this tournament."
  end

  def registration_params
    params.require(:registration).permit(:athlete_id, :registered_weight, :payment_receipt, tournament_category_ids: [])
  end

  def set_registration_collections
    @athletes = manageable_athletes.includes(:academy).order(:first_name, :last_name)
    @categories = @tournament.tournament_categories.order(:name)
  end

  def manageable_athletes
    owned_academy_ids = current_user.owned_academies.approved.select(:id)
    Athlete.where(user_id: current_user.id).or(Athlete.where(academy_id: owned_academy_ids)).distinct
  end

  def selected_category_ids
    ids = Array(params[:category_id]).reject(&:blank?).map(&:to_s)
    athlete_id = @registration.athlete_id
    ids += @tournament.registrations.draft.where(athlete_id: athlete_id).pluck(:tournament_category_id).map(&:to_s) if athlete_id.present?
    ids.uniq
  end

  def save_category_registrations(submit_registration:)
    @registration.athlete = @athlete
    validate_registration_selection(submit_registration)
    return false if @registration.errors.any?

    Registration.transaction do
      @selected_category_ids.each do |category_id|
        category = @tournament.tournament_categories.find(category_id)
        registration = @tournament.registrations.find_or_initialize_by(athlete: @athlete, tournament_category: category)
        registration.registered_weight = registration_params[:registered_weight].presence || @athlete.weight
        registration.status = submit_registration ? :pending : :draft
        attach_payment_receipt(registration) if submit_registration
        registration.save!
      end
    end
    true
  rescue ActiveRecord::RecordInvalid => error
    @registration.errors.merge!(error.record.errors)
    false
  end

  def validate_registration_selection(submit_registration)
    @registration.errors.add(:athlete, "must be selected") if @athlete.blank?
    @registration.errors.add(:tournament_category, "must include at least one category") if @selected_category_ids.blank?
    return unless submit_registration

    @registration.errors.add(:payment_receipt, "must be uploaded") if registration_params[:payment_receipt].blank?
  end

  def attach_payment_receipt(registration)
    receipt = registration_params[:payment_receipt]
    receipt.tempfile.rewind if receipt.respond_to?(:tempfile)
    registration.payment_receipt.attach(receipt)
  end

  def status_sort_sql
    Arel.sql("CASE registrations.status WHEN 6 THEN 0 WHEN 0 THEN 1 WHEN 1 THEN 2 WHEN 4 THEN 3 WHEN 2 THEN 4 WHEN 5 THEN 5 ELSE 6 END")
  end
end
