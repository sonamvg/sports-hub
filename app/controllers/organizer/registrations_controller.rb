module Organizer
  class RegistrationsController < ApplicationController
    before_action :require_user
    before_action :set_registration, only: %i[show approve reject receipt]

    def index
      @tournament = visible_registrations_tournament
      @registrations = visible_registrations
        .then { |scope| @tournament ? scope.where(tournament_id: @tournament.id) : scope }
        .includes(:athlete, :tournament, :tournament_category, :registration_weight_checks)
        .with_attached_payment_receipt
        .order(status_sort_sql, created_at: :desc)

      batch_ids = @registrations.filter_map(&:submission_batch_id).uniq
      batch_registrations = Registration.where(submission_batch_id: batch_ids).includes(:tournament_category).group_by(&:submission_batch_id)
      @batch_totals = batch_registrations.transform_values { |rows| Registration.total_fee(rows) }
      @batch_counts = batch_registrations.transform_values(&:count)
      @batch_category_counts = batch_registrations.transform_values { |rows| rows.map(&:tournament_category_id).uniq.size }
    end

    def show
      @action_logs = @registration.registration_action_logs.includes(:actor).order(created_at: :desc) if super_admin?
    end

    def approve
      if @registration.review!(actor: current_user, status: :approved)
        redirect_to organizer_registrations_path, notice: "Registration accepted."
      else
        redirect_to organizer_registrations_path, alert: review_failure_alert
      end
    end

    def reject
      if @registration.review!(actor: current_user, status: :rejected)
        redirect_to organizer_registrations_path, notice: "Registration denied."
      else
        redirect_to organizer_registrations_path, alert: review_failure_alert
      end
    end

    def receipt
      raise ActiveRecord::RecordNotFound unless @registration.payment_receipt.attached?

      send_data @registration.payment_receipt.download,
        filename: @registration.payment_receipt.filename.to_s,
        type: @registration.payment_receipt.content_type,
        disposition: "inline"
    end

    private

    def review_failure_alert
      return "Registration has already been reviewed." if @registration.errors[:base].exclude?("tournament has been #{@registration.tournament.status}")

      "This registration can no longer be reviewed because the tournament has been #{@registration.tournament.status}."
    end

    def visible_registrations
      Registration.where(tournament_id: managed_tournament_ids).decided
    end

    # Scopes the index to one tournament when a tournament_id is given (the
    # per-tournament "Tournament athletes" link) — only resolved if the
    # current organizer actually manages that tournament, so passing an
    # arbitrary id just falls back to the unscoped (all-managed-tournaments)
    # list rather than leaking another organizer's tournament.
    def visible_registrations_tournament
      return if params[:tournament_id].blank?

      Tournament.where(id: managed_tournament_ids).find_by(id: params[:tournament_id])
    end

    # A super admin can manage every tournament (same as can_manage_tournament?
    # and every other "who can see/manage this tournament" scope in the app,
    # e.g. TournamentsController#visible_tournaments) — without this, a super
    # admin filtering this page to a tournament they don't personally own or
    # collaborate on would see "no athletes registered" even though real,
    # pending registrations exist and are visible on the tournament's own page.
    def managed_tournament_ids
      return Tournament.select(:id) if super_admin?

      Tournament
        .left_joins(:tournament_organizers)
        .where("tournaments.organizer_id = :user_id OR tournament_organizers.user_id = :user_id", user_id: current_user.id)
        .distinct
        .select(:id)
    end

    def set_registration
      @registration = visible_registrations.find(params[:id])
    end

    def status_sort_sql
      Arel.sql("CASE registrations.status WHEN 0 THEN 0 WHEN 1 THEN 1 WHEN 4 THEN 2 WHEN 2 THEN 3 WHEN 5 THEN 4 ELSE 5 END")
    end
  end
end
