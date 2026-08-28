class TournamentCategoriesController < ApplicationController
  before_action :set_tournament
  before_action :set_category, only: :show

  def index
    @categories = @tournament.tournament_categories.order(:name)
  end

  def show; end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def set_category
    @category = @tournament.tournament_categories.find(params[:id])
  end
end
