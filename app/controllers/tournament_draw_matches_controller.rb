class TournamentDrawMatchesController < ApplicationController
  before_action :require_user
  before_action :set_match
  before_action :require_tournament_manager

  def result
    if freeze_result?
      freeze_result
    else
      save_score_draft
    end
  end

  private

  def freeze_result
    if @match.record_result!(actor: current_user, attributes: result_params)
      redirect_to draw_tournament_path(@match.tournament_draw.tournament), notice: "Match result frozen."
    else
      redirect_to draw_tournament_path(@match.tournament_draw.tournament), alert: @match.errors.full_messages.to_sentence
    end
  end

  def save_score_draft
    if @match.save_score_draft!(attributes: result_params)
      redirect_to draw_tournament_path(@match.tournament_draw.tournament), notice: "Score saved."
    else
      redirect_to draw_tournament_path(@match.tournament_draw.tournament), alert: @match.errors.full_messages.to_sentence
    end
  end

  def freeze_result?
    params[:score_action] == "Freeze result"
  end

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
      :red_round_3_points, :blue_round_3_points
    )
  end
end
