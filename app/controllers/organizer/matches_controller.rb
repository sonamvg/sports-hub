module Organizer
  class MatchesController < ApplicationController
    before_action :require_user
    before_action :set_match

    def update
      unless @match.ready_for_result?
        return redirect_to draw_path, alert: "This match is not ready for a result."
      end

      unless Match.decisions.key?(match_params[:decision])
        return redirect_to draw_path, alert: "Select how the match was decided."
      end

      if match_params[:decision] == "points"
        record_points_result
      else
        record_manual_result
      end
    rescue Match::NotReadyForResultError, ActiveRecord::RecordInvalid => e
      redirect_to draw_path, alert: e.message
    end

    private

    def set_match
      @match = Match.includes(tournament_category: :tournament).find(params[:id])
      raise ActiveRecord::RecordNotFound unless can_manage_tournament?(@match.tournament_category.tournament)
    end

    def draw_path
      organizer_tournament_tournament_category_draw_path(@match.tournament_category.tournament, @match.tournament_category)
    end

    def record_points_result
      result = MatchScoreDecider.new(rounds_params).call

      unless result.success?
        return redirect_to draw_path, alert: result.error
      end

      winner_id = result.winner_side == "one" ? @match.registration_one_id : @match.registration_two_id
      @match.record_result!(winner_registration_id: winner_id, decision: :points, score_data: result.score_data)
      redirect_to draw_path, notice: "Result saved."
    end

    def record_manual_result
      winner_side = match_params[:winner_side]
      unless %w[one two].include?(winner_side)
        return redirect_to draw_path, alert: "Select which athlete won."
      end

      winner_id = winner_side == "one" ? @match.registration_one_id : @match.registration_two_id
      @match.record_result!(winner_registration_id: winner_id, decision: match_params[:decision], score_data: {})
      redirect_to draw_path, notice: "Result saved."
    end

    def match_params
      params.require(:match).permit(:decision, :winner_side, rounds: [ :points_one, :points_two, :superiority_winner ])
    end

    def rounds_params
      (match_params[:rounds] || {}).values.map { |round| round.to_h.symbolize_keys }
    end
  end
end
