class TournamentCategoriesController < ApplicationController
  before_action :set_tournament
  before_action :set_category, only: :show

  def index
    @categories = @tournament.tournament_categories.order(:name)
  end

  def show
    return unless @category.draw_generated?

    @bracket_data = BracketPresenter.new(@category).as_json
    @medal_standings = @category.medal_standings
    @upcoming_matches = @category.matches.includes(:registration_one, :registration_two).select(&:ready_for_result?)
    @completed_matches = @category.matches.includes(:registration_one, :registration_two, :winner_registration).where(status: :completed).order(:round_number, :slot_position)
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def set_category
    @category = @tournament.tournament_categories.find(params[:id])
  end
end
