class TournamentsController < ApplicationController
  require "csv"

  before_action :require_user, except: %i[index show]
  before_action :require_verified_organizer, only: %i[new create]
  before_action :set_tournament, only: %i[show edit update venue_setup update_venue_setup draw set_draw]
  before_action :require_tournament_manager, only: %i[edit update venue_setup update_venue_setup draw set_draw]
  before_action :set_available_organizers, only: %i[new create edit update]

  def index
    set_filter_options
    @tournaments = filtered_tournaments.order(tournament_sort_sql, start_date: :desc, created_at: :desc)
    @tournaments, @pagination = paginate(@tournaments)
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
      category_alert = sync_category_setup
      invite_notice, invite_alert = send_organizer_invitation
      redirect_to @tournament, notice: ["Tournament created.", invite_notice].compact.join(" "), alert: [category_alert, invite_alert].compact.to_sentence.presence
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @categories = @tournament.tournament_categories.order(:name)
    @registrations = visible_tournament_registrations
  end

  def edit; end

  def venue_setup
    redirect_to @tournament, alert: "Venue setup opens after registration closes." unless @tournament.registration_closed_for_weight_check?
  end

  def update_venue_setup
    unless @tournament.registration_closed_for_weight_check?
      redirect_to @tournament, alert: "Venue setup opens after registration closes."
      return
    end

    if @tournament.update(venue_setup_params)
      redirect_to @tournament, notice: "Venue setup updated."
    else
      render :venue_setup, status: :unprocessable_entity
    end
  end

  def draw; end

  def set_draw
    unless @tournament.registration_closed_for_weight_check?
      redirect_to @tournament, alert: "Draw setup can start after registration closes."
      return
    end

    @tournament.update!(status: :draw_scheduling)
    redirect_to draw_tournament_path(@tournament), notice: "Draw setup started. Late athlete registrations are now locked."
  end

  def update
    @tournament.assign_attributes(tournament_params)
    apply_submit_intent(@tournament)
    if @tournament.save
      sync_tournament_organizers
      category_alert = sync_category_setup
      invite_notice, invite_alert = send_organizer_invitation
      redirect_to @tournament, notice: ["Tournament updated.", invite_notice].compact.join(" "), alert: [category_alert, invite_alert].compact.to_sentence.presence
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

  def visible_tournament_registrations
    return Registration.none unless current_user

    registrations = @tournament.registrations.where.not(status: :draft).includes(:tournament_category, athlete: :academy).order(status_sort_sql, created_at: :desc)
    return registrations if can_manage_tournament?(@tournament)

    registrations.joins(:athlete).where(athletes: { user_id: current_user.id })
  end

  def status_sort_sql
    Arel.sql("CASE registrations.status WHEN 0 THEN 0 WHEN 1 THEN 1 WHEN 4 THEN 2 WHEN 2 THEN 3 WHEN 5 THEN 4 ELSE 5 END")
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

  def send_organizer_invitation
    email = params.dig(:tournament, :invite_organizer_email).to_s.downcase.squish
    return [nil, nil] if email.blank?

    invitation = @tournament.tournament_organizer_invitations.build(email: email, invited_by: current_user)
    if invitation.save
      TournamentOrganizerInvitationMailer.with(invitation: invitation).invite.deliver_later
      ["Organizer invitation sent.", nil]
    else
      [nil, invitation.errors.full_messages.to_sentence]
    end
  end

  def sync_category_setup
    return unless can_edit_tournament_categories?(@tournament)

    case @tournament.category_generation_method
    when "Auto-generate from eligibility rules"
      create_default_categories_from_form
    when "Manual categories"
      create_manual_categories_from_form
    when "Import categories"
      import_categories_from_file
    end
  end

  def create_default_categories_from_form
    category_errors = []
    category_rows_from(params.dig(:tournament, :default_category_templates)).each do |row|
      next unless row[:selected] == "1"

      attributes = category_attributes_from(row)
      next if attributes[:event_type].blank?

      category = @tournament.tournament_categories.find_or_initialize_by(attributes)
      category_errors << category.errors.full_messages.to_sentence unless category.persisted? || category.save
    end
    category_errors.to_sentence.presence
  end

  def create_manual_categories_from_form
    category_errors = []
    category_rows_from(params.dig(:tournament, :manual_categories)).each do |row|
      attributes = category_attributes_from(row)
      next if attributes.values.all?(&:blank?)

      category = @tournament.tournament_categories.build(attributes)
      category_errors << category.errors.full_messages.to_sentence unless category.save
    end
    category_errors.to_sentence.presence
  end

  def import_categories_from_file
    upload = params.dig(:tournament, :category_import_file)
    return if upload.blank?

    extension = File.extname(upload.original_filename.to_s).downcase
    return "XLSX import needs a spreadsheet parser gem. Export the sheet as CSV and import again." if extension == ".xlsx"

    text = upload.read.to_s
    separator = extension == ".tsv" || extension == ".xls" ? "\t" : ","
    rows = CSV.parse(text, headers: true, col_sep: separator)
    category_errors = []

    rows.each do |row|
      attributes = category_attributes_from(row.to_h)
      next if attributes.values.all?(&:blank?)

      category = @tournament.tournament_categories.build(attributes)
      category_errors << "Row #{row.to_h.inspect}: #{category.errors.full_messages.to_sentence}" unless category.save
    end
    category_errors.to_sentence.presence
  rescue CSV::MalformedCSVError
    "Category import file could not be read. Use CSV with headers: event_type, gender, age_min, age_max, weight_min, weight_max, belt_min, belt_max."
  end

  def category_attributes_from(row)
    row = row.to_h.with_indifferent_access
    {
      event_type: row[:event_type].to_s.squish.presence,
      gender: row[:gender].to_s.squish.presence,
      age_min: row[:age_min].presence,
      age_max: row[:age_max].presence,
      weight_min: row[:weight_min].presence,
      weight_max: row[:weight_max].presence,
      belt_min: row[:belt_min].to_s.squish.presence,
      belt_max: row[:belt_max].to_s.squish.presence
    }
  end

  def category_rows_from(value)
    case value
    when ActionController::Parameters
      value.to_unsafe_h.values.map { |row| row.with_indifferent_access }
    when Hash
      value.values.map { |row| row.with_indifferent_access }
    else
      Array(value).map { |row| row.to_h.with_indifferent_access }
    end
  end

  def tournament_params
    permitted = params.require(:tournament).permit(
      :name, :slug, :description, :venue, :city, :state, :country, :start_date, :end_date,
      :registration_opens_at, :registration_closes_at, :status, :website_url,
      :tournament_level, :organizing_organization, :time_zone, :primary_contact_name,
      :primary_contact_email, :primary_contact_phone, :competition_formats,
      :eligibility_summary, :category_generation_method, :registration_capacity,
      :registration_fee, :currency, :required_documents, :refund_policy,
      :payment_account_name, :payment_bank_name, :payment_account_number,
      :payment_ifsc, :payment_instructions,
      :logo_image, :banner_image,
      competition_format_options: [], competition_format_other: [],
      eligibility_options: [], eligibility_other: [],
      required_document_options: [], required_document_other: [],
      refund_policy_options: []
    )

    compose_checklist_fields(permitted)
  end

  def venue_setup_params
    params.require(:tournament).permit(:courts_count)
  end

  def apply_submit_intent(tournament)
    tournament.status = :draft if params[:commit] == "Save as Draft"
    tournament.status = :scheduled if params[:commit] == "Publish" && tournament.draft?
  end

  def compose_checklist_fields(permitted)
    if permitted.key?(:competition_format_options) || permitted.key?(:competition_format_other)
      permitted[:competition_formats] = joined_checklist(permitted.delete(:competition_format_options), permitted.delete(:competition_format_other))
    end

    if permitted.key?(:eligibility_options) || permitted.key?(:eligibility_other)
      permitted[:eligibility_summary] = joined_checklist(permitted.delete(:eligibility_options), permitted.delete(:eligibility_other))
    end

    if permitted.key?(:required_document_options) || permitted.key?(:required_document_other)
      permitted[:required_documents] = joined_checklist(permitted.delete(:required_document_options), permitted.delete(:required_document_other))
    end

    permitted[:refund_policy] = joined_checklist(permitted.delete(:refund_policy_options), []) if permitted.key?(:refund_policy_options)
    permitted
  end

  def joined_checklist(options, other_values)
    (Array(options) + Array(other_values)).map { |value| value.to_s.squish }.reject(&:blank?).uniq.join(", ")
  end

  def filtered_tournaments
    tournaments = Tournament.all
    query = params[:q].to_s.squish.downcase
    if query.present?
      tournaments = tournaments.where(
        "LOWER(name) LIKE :query OR LOWER(COALESCE(venue, '')) LIKE :query OR LOWER(COALESCE(city, '')) LIKE :query OR LOWER(COALESCE(state, '')) LIKE :query OR LOWER(COALESCE(country, '')) LIKE :query",
        query: "%#{query}%"
      )
    end

    tournaments = tournaments.where("LOWER(country) = ?", params[:country].to_s.squish.downcase) if params[:country].present?
    tournaments = tournaments.where("LOWER(state) = ?", params[:state].to_s.squish.downcase) if params[:state].present?
    tournaments
  end

  def set_filter_options
    @filter_countries = Tournament.where.not(country: [nil, ""]).distinct.order(:country).pluck(:country)
    @filter_states = Tournament.where.not(state: [nil, ""]).distinct.order(:state).pluck(:state)
  end

  def tournament_sort_sql
    today = ActiveRecord::Base.connection.quote(Date.current)
    Arel.sql("CASE WHEN end_date < #{today} OR status IN (2, 4, 5, 10) THEN 1 ELSE 0 END ASC")
  end
end
