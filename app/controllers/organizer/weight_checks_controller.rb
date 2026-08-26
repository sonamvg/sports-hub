module Organizer
  class WeightChecksController < ApplicationController
    before_action :require_user
    before_action :set_tournament, only: :index
    before_action :set_registration, only: :create

    def index
      unless @tournament.registration_closed_for_weight_check?
        redirect_to @tournament, alert: "Weight check opens after registration closes."
        return
      end

      if @tournament.draw_scheduling?
        redirect_to draw_tournament_path(@tournament), alert: "Weight check is locked after draw setup starts."
        return
      end

      @query = params[:q].to_s.squish
      @registrations = weight_check_registrations
    end

    def create
      weight_check = @registration.registration_weight_checks.build(
        checked_by: current_user,
        weight: weight_check_params[:weight]
      )

      if weight_check.save
        redirect_to organizer_tournament_weight_checks_path(@registration.tournament, q: params[:q]), notice: weight_check_notice(weight_check)
      else
        redirect_to organizer_tournament_weight_checks_path(@registration.tournament, q: params[:q]), alert: weight_check.errors.full_messages.to_sentence
      end
    end

    private

    def set_tournament
      @tournament = Tournament.find(params[:tournament_id])
      raise ActiveRecord::RecordNotFound unless can_manage_tournament?(@tournament)
    end

    def set_registration
      @registration = Registration.includes(:tournament, :tournament_category, :registration_weight_checks).find(params[:registration_id])
      raise ActiveRecord::RecordNotFound unless can_manage_tournament?(@registration.tournament)
    end

    def weight_check_registrations
      registrations = @tournament.registrations
        .includes(:tournament_category, :registration_weight_checks, athlete: :academy)
        .where(status: %i[approved weight_verified disqualified])
        .order(status_sort_sql, created_at: :desc)

      return registrations if @query.blank?

      registrations.joins(:athlete).where(
        "LOWER(athletes.first_name) LIKE :query OR LOWER(athletes.last_name) LIKE :query OR LOWER(CONCAT(athletes.first_name, ' ', athletes.last_name)) LIKE :query OR LOWER(COALESCE(athletes.association_id, '')) LIKE :query",
        query: "%#{@query.downcase}%"
      )
    end

    def status_sort_sql
      Arel.sql("CASE registrations.status WHEN 1 THEN 0 WHEN 4 THEN 1 WHEN 5 THEN 2 ELSE 3 END")
    end

    def weight_check_params
      params.require(:registration_weight_check).permit(:weight)
    end

    def weight_check_notice(weight_check)
      if weight_check.passed?
        "Weight check passed. Athlete moved to draw list."
      elsif weight_check.attempt_number == 3
        "Third weight check failed. Athlete disqualified."
      else
        "Weight check attempt #{weight_check.attempt_number} saved."
      end
    end
  end
end
