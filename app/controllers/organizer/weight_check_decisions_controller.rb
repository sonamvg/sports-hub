module Organizer
  class WeightCheckDecisionsController < ApplicationController
    before_action :require_user
    before_action :set_registration

    def disqualify
      if @registration.weight_check_decision_pending? && @registration.review!(actor: current_user, status: :disqualified)
        redirect_to organizer_tournament_weight_checks_path(@registration.tournament, redirect_params), notice: "Athlete disqualified."
      else
        redirect_to organizer_tournament_weight_checks_path(@registration.tournament, redirect_params), alert: "Unable to disqualify this athlete."
      end
    end

    def change_category
      category = @registration.eligible_category_change_targets.find_by(id: params[:tournament_category_id])

      unless @registration.weight_check_decision_pending? && category
        redirect_to organizer_tournament_weight_checks_path(@registration.tournament, redirect_params), alert: "Unable to change this athlete's category."
        return
      end

      new_registration = @registration.move_to_category!(category: category, actor: current_user)
      redirect_to organizer_tournament_weight_checks_path(@registration.tournament, redirect_params.merge(highlight: new_registration.id)),
        notice: "Moved to #{category.name}. Weigh-in restarts fresh in the new category."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to organizer_tournament_weight_checks_path(@registration.tournament, redirect_params), alert: "Couldn't move athlete: #{e.record.errors.full_messages.to_sentence}"
    end

    private

    def set_registration
      @registration = Registration.includes(:tournament, :tournament_category, :registration_weight_checks).find(params[:registration_id])
      raise ActiveRecord::RecordNotFound unless can_manage_tournament?(@registration.tournament)
    end

    def redirect_params
      { q: params[:q], category_id: params[:category_id] }
    end
  end
end
