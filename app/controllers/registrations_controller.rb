class RegistrationsController < ApplicationController
  before_action :require_user
  before_action :set_tournament
  before_action :ensure_registration_open, only: %i[new individual group payment submit create]
  before_action :set_athletes, only: %i[individual group]

  def index
    @registrations = @tournament.registrations.where(athlete: manageable_athletes).decided.includes(:athlete, :tournament_category).order(status_sort_sql, created_at: :desc)
  end

  # Athlete self-registration is a separate, single-page direct flow (no
  # cart/draft, no Pair/Team Poomsae) — deliberately not the academy-owner
  # multi-screen flow below, since an athlete only ever registers themselves
  # in one shot. Academy owners keep seeing the existing entry-choice screen,
  # rendered by the default `new` template further down.
  def new
    return unless current_user.athlete?

    # ApplicationController#require_athlete_profile_completion already
    # guarantees an athlete-role user reaching here has a profile.
    @athlete = current_user.athletes.first
    @suggestions = suggested_categories_for(@athlete)
    @selected_category_ids = []
    render :athlete_new
  end

  def create
    raise ActiveRecord::RecordNotFound unless current_user.athlete?

    create_athlete_registration
  end

  def individual
    @athlete = selected_athlete
    @draft_registrations = draft_registrations
    @selected_category_ids = []

    if request.post?
      create_individual_draft
    elsif @athlete
      @suggestions = suggested_categories_for(@athlete)
    end
  end

  def group
    if current_user.athlete?
      redirect_to individual_tournament_registrations_path(@tournament), alert: "Pair and Team Poomsae aren't available for self-registration."
      return
    end

    @team_type = %w[pair_poomsae team_poomsae].include?(params[:team_type]) ? params[:team_type] : "pair_poomsae"
    @group_categories = @tournament.tournament_categories.where(event_type: @team_type).order(:name)
    # A team's members must all share one academy, so an athlete with no
    # academy at all (e.g. self-registered, not on any roster) could never
    # satisfy that — leaving them selectable here just invites the "must all
    # belong to the same academy" error for no reason.
    @athletes = @athletes.where.not(academy_id: nil)
    @draft_registrations = draft_registrations

    create_group_draft if request.post?
  end

  def payment
    @draft_registrations = draft_registrations
  end

  def submit
    @draft_registrations = draft_registrations

    if @draft_registrations.empty?
      redirect_to individual_tournament_registrations_path(@tournament), alert: "Add at least one athlete or entry before paying."
      return
    end

    receipt_blob = build_payment_receipt_blob
    needs_receipt = @draft_registrations.any? { |registration| !registration.tournament_category.free? }
    if needs_receipt && receipt_blob.blank?
      @error = "Payment receipt must be uploaded"
      render :payment, status: :unprocessable_entity
      return
    end

    begin
      Registration.transaction do
        @tournament.lock!

        unless can_register_for_tournament?(@tournament) || @tournament.late_registration_allowed_for?(current_user)
          @error = "Registration is no longer open for this tournament"
          raise ActiveRecord::Rollback
        end

        @draft_registrations.each do |registration|
          registration.payment_receipt.attach(receipt_blob) if receipt_blob
          registration.status = :pending
          registration.save!
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      @error = e.record.errors.full_messages.to_sentence
    end

    if @error
      render :payment, status: :unprocessable_entity
    else
      redirect_to tournament_registrations_path(@tournament), notice: "Registration submitted to tournament organizers for approval."
    end
  end

  def destroy
    registration = draft_registrations.find(params[:id])
    Registration.where(submission_batch_id: registration.submission_batch_id).where(athlete: manageable_athletes).destroy_all
    redirect_back fallback_location: individual_tournament_registrations_path(@tournament), notice: "Removed from your registration."
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def set_athletes
    @athletes = manageable_athletes.includes(:academy).order(:first_name, :last_name)
  end

  def ensure_registration_open
    return if can_register_for_tournament?(@tournament)
    return if @tournament.late_registration_allowed_for?(current_user)

    redirect_to @tournament, alert: "Registration is not open for this tournament."
  end

  def manageable_athletes
    current_user.manageable_athletes
  end

  def selected_athlete
    manageable_athletes.find_by(id: params[:athlete_id]) || manageable_athletes.order(:first_name, :last_name).first
  end

  def individual_categories
    @tournament.tournament_categories.where.not(event_type: TournamentCategory::GROUP_EVENT_TYPES).order(:weight_min)
  end

  def suggested_categories_for(athlete)
    weight = params[:registered_weight].presence || athlete.weight
    TournamentCategory.suggested_individual_categories(individual_categories, athlete: athlete, as_of: @tournament.start_date, weight: weight)
  end

  def draft_registrations
    @tournament.registrations.where(athlete: manageable_athletes, status: :draft).includes(:athlete, :tournament_category).order(:submission_batch_id, :created_at)
  end

  def next_destination
    case params[:next]
    when "group" then group_tournament_registrations_path(@tournament, team_type: params[:team_type])
    when "individual" then individual_tournament_registrations_path(@tournament)
    else payment_tournament_registrations_path(@tournament)
    end
  end

  # Athlete self-registration: one form, one submit, real `pending` rows —
  # no draft/cart, since there's only ever one athlete (themselves) and no
  # group option to loop back for. Kept entirely separate from the academy
  # owner's draft-cart methods below.
  def create_athlete_registration
    athlete = current_user.athletes.first
    category_ids = Array(params[:tournament_category_ids]).reject(&:blank?).uniq
    if category_ids.blank?
      render_athlete_new_error(athlete, category_ids, "Choose at least one category.")
      return
    end

    categories = individual_categories.where(id: category_ids)
    if categories.size != category_ids.size
      render_athlete_new_error(athlete, category_ids, "Included a category that is no longer available; please reselect categories and resubmit.")
      return
    end

    skipped_categories = []
    registrable_categories = categories.reject do |category|
      already_registered = @tournament.registrations.exists?(athlete: athlete, tournament_category: category)
      skipped_categories << category if already_registered
      already_registered
    end

    if registrable_categories.empty?
      redirect_to new_tournament_registration_path(@tournament),
        alert: "You already have a registration decision for #{skipped_categories.map(&:name).to_sentence} — check My Registrations for its status."
      return
    end

    receipt_blob = build_payment_receipt_blob
    needs_receipt = registrable_categories.any? { |category| !category.free? }
    if needs_receipt && receipt_blob.blank?
      render_athlete_new_error(athlete, category_ids, "Payment receipt must be uploaded")
      return
    end

    weight = params[:registered_weight].presence
    submission_batch_id = SecureRandom.uuid

    begin
      Registration.transaction do
        @tournament.lock!

        unless can_register_for_tournament?(@tournament) || @tournament.late_registration_allowed_for?(current_user)
          @error = "Registration is no longer open for this tournament"
          raise ActiveRecord::Rollback
        end

        registrable_categories.each do |category|
          registration = @tournament.registrations.build(
            athlete: athlete,
            tournament_category: category,
            status: :pending,
            registered_weight: weight,
            fee_amount: category.effective_registration_fee,
            fee_currency: @tournament.currency.presence || "INR",
            submission_batch_id: submission_batch_id
          )
          registration.payment_receipt.attach(receipt_blob) if receipt_blob
          registration.save!
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      @error = e.record.errors.full_messages.to_sentence
    end

    if @error
      render_athlete_new_error(athlete, category_ids, @error)
      return
    end

    notice = "Registration submitted to tournament organizers for approval."
    notice += " #{skipped_categories.map(&:name).to_sentence} #{skipped_categories.one? ? "was" : "were"} skipped since you already had a decision for it." if skipped_categories.any?
    redirect_to tournament_registrations_path(@tournament), notice: notice
  end

  def render_athlete_new_error(athlete, category_ids, message)
    @error = message
    @athlete = athlete
    @suggestions = suggested_categories_for(athlete)
    @selected_category_ids = category_ids
    render :athlete_new, status: :unprocessable_entity
  end

  def create_individual_draft
    athlete = manageable_athletes.find_by(id: params[:athlete_id])
    category_ids = Array(params[:tournament_category_ids]).reject(&:blank?).uniq

    if athlete.blank? || category_ids.blank?
      @error = "Choose an athlete and at least one category."
      @suggestions = suggested_categories_for(athlete) if athlete
      @athlete = athlete
      render :individual, status: :unprocessable_entity
      return
    end

    categories = individual_categories.where(id: category_ids)
    if categories.size != category_ids.size
      @error = "included a category that is no longer available; please reselect categories and resubmit"
      @athlete = athlete
      @suggestions = suggested_categories_for(athlete)
      render :individual, status: :unprocessable_entity
      return
    end

    batch_id = SecureRandom.uuid
    weight = params[:registered_weight].presence
    skipped_categories = []
    added = false

    categories.each do |category|
      registration = @tournament.registrations.find_or_initialize_by(athlete: athlete, tournament_category: category)
      if registration.persisted? && !registration.draft?
        skipped_categories << category
        next
      end

      registration.assign_attributes(
        status: :draft,
        registered_weight: weight,
        fee_amount: category.effective_registration_fee,
        fee_currency: @tournament.currency.presence || "INR",
        submission_batch_id: batch_id
      )

      unless registration.save
        @error = registration.errors.full_messages.to_sentence
        @athlete = athlete
        @suggestions = suggested_categories_for(athlete)
        render :individual, status: :unprocessable_entity
        return
      end

      added = true
    end

    if !added && skipped_categories.any?
      redirect_to individual_tournament_registrations_path(@tournament, athlete_id: athlete.id),
        alert: "#{athlete.full_name} already has a registration decision for #{skipped_categories.map(&:name).to_sentence} — check My Registrations for its status."
      return
    end

    notice = skipped_categories.any? ? "Added. #{athlete.full_name} already had a decision recorded for #{skipped_categories.map(&:name).to_sentence}, so that one was skipped." : nil
    redirect_to next_destination, notice: notice
  end

  def create_group_draft
    category = @tournament.tournament_categories.find_by(id: params[:tournament_category_id])
    athlete_ids = Array(params[:athlete_ids]).reject(&:blank?).uniq
    athletes = manageable_athletes.where(id: athlete_ids)

    # Nothing was actually filled in on this screen — most often someone
    # switching straight back to "individual" without building a team.
    # There's nothing to validate or save, so just navigate instead of
    # bouncing them off a "choose a category" error for a form they never
    # meant to submit.
    if params[:tournament_category_id].blank? && athlete_ids.empty?
      redirect_to next_destination
      return
    end

    if category.blank? || category.required_athlete_count <= 1
      @error = "Choose a Pair or Team Poomsae category."
      render :group, status: :unprocessable_entity
      return
    end

    if athletes.size != category.required_athlete_count
      @error = "Select exactly #{category.required_athlete_count} team members for this category."
      render :group, status: :unprocessable_entity
      return
    end

    academy_ids = athletes.map(&:academy_id).uniq
    if academy_ids.size != 1 || academy_ids.first.nil?
      @error = "Team members must all belong to the same academy."
      render :group, status: :unprocessable_entity
      return
    end

    already_decided = athletes.select do |athlete|
      existing = @tournament.registrations.find_by(athlete: athlete, tournament_category: category)
      existing && !existing.draft?
    end
    if already_decided.any?
      @error = "#{already_decided.map(&:full_name).to_sentence} #{already_decided.one? ? "already has" : "already have"} a registration decision for this category — check My Registrations for its status."
      render :group, status: :unprocessable_entity
      return
    end

    batch_id = SecureRandom.uuid

    athletes.each do |athlete|
      registration = @tournament.registrations.find_or_initialize_by(athlete: athlete, tournament_category: category)

      registration.assign_attributes(
        status: :draft,
        fee_amount: category.effective_registration_fee,
        fee_currency: @tournament.currency.presence || "INR",
        submission_batch_id: batch_id
      )

      unless registration.save
        @error = registration.errors.full_messages.to_sentence
        render :group, status: :unprocessable_entity
        return
      end
    end

    redirect_to next_destination
  end

  def build_payment_receipt_blob
    receipt = params[:payment_receipt]
    return if receipt.blank?

    ActiveStorage::Blob.create_and_upload!(
      io: receipt,
      filename: receipt.original_filename,
      content_type: receipt.content_type
    )
  end

  def status_sort_sql
    Arel.sql("CASE registrations.status WHEN 6 THEN 0 WHEN 0 THEN 1 WHEN 1 THEN 2 WHEN 4 THEN 3 WHEN 2 THEN 4 WHEN 5 THEN 5 ELSE 6 END")
  end
end
