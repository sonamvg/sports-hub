module Organizer
  class RegistrationsController < ApplicationController
    before_action :require_user
    before_action :set_registration, only: %i[show approve reject]

    def index
      @registrations = visible_registrations
        .includes(:athlete, :tournament, :tournament_category, :registration_weight_checks)
        .with_attached_payment_receipt
        .order(status_sort_sql, created_at: :desc)
    end

    def show
      @action_logs = @registration.registration_action_logs.includes(:actor).order(created_at: :desc) if super_admin?
    end

    def approve
      @registration.review!(actor: current_user, status: :approved)
      redirect_to organizer_registrations_path, notice: "Registration accepted."
    end

    def reject
      @registration.review!(actor: current_user, status: :rejected)
      redirect_to organizer_registrations_path, notice: "Registration denied."
    end

    private

    def visible_registrations
      return Registration.all if super_admin?

      tournament_ids = Tournament
        .left_joins(:tournament_organizers)
        .where("tournaments.organizer_id = :user_id OR tournament_organizers.user_id = :user_id", user_id: current_user.id)
        .distinct
        .select(:id)

      Registration.where(tournament_id: tournament_ids)
    end

    def set_registration
      @registration = visible_registrations.find(params[:id])
    end

    def status_sort_sql
      Arel.sql("CASE registrations.status WHEN 0 THEN 0 WHEN 1 THEN 1 WHEN 4 THEN 2 WHEN 2 THEN 3 WHEN 5 THEN 4 ELSE 5 END")
    end
  end
end
