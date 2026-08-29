class TournamentDrawMatchesController < ApplicationController
  before_action :require_user
  before_action :set_match
  before_action :require_tournament_manager

  def result
    if @match.record_result!(actor: current_user, attributes: result_params)
      redirect_to draw_tournament_path(@match.tournament_draw.tournament), notice: "Match result saved."
    else
      redirect_to draw_tournament_path(@match.tournament_draw.tournament), alert: @match.errors.full_messages.to_sentence
    end
  end

  private

  def set_match
    @match = TournamentDrawMatch.includes(tournament_draw: :tournament).find(params[:id])
  end

  def require_tournament_manager
    raise ActiveRecord::RecordNotFound unless can_manage_tournament?(@match.tournament_draw.tournament)
  end

  def result_params
    params.require(:tournament_draw_match).permit(
      :red_round_1_points, :blue_round_1_points,
      :red_round_2_points, :blue_round_2_points,
      :red_round_3_points, :blue_round_3_points,
      :red_head_guard_color, :blue_head_guard_color,
      :winner_registration_id
    )
  end
end
