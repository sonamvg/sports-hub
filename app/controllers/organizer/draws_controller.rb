module Organizer
  class DrawsController < ApplicationController
    before_action :require_user
    before_action :set_category

    def show
      @eligible_count = @category.draw_eligible_registrations.count
      return unless @category.draw_generated?

      @bracket_data = BracketPresenter.new(@category).as_json
      @medal_standings = @category.medal_standings
      @ready_matches = @category.matches.includes(:registration_one, :registration_two).select(&:ready_for_result?)
    end

    def create
      if @category.draw_generated?
        if @category.draw_locked?
          return redirect_to organizer_tournament_tournament_category_draw_path(@tournament, @category),
            alert: "The draw is locked because a result has already been recorded."
        end

        @category.reset_draw!
      end

      result = BracketGenerator.new(@category).call

      if result.success?
        redirect_to organizer_tournament_tournament_category_draw_path(@tournament, @category), notice: "Draw generated."
      else
        redirect_to organizer_tournament_tournament_category_draw_path(@tournament, @category), alert: result.error
      end
    end

    private

    def set_category
      @tournament = Tournament.find(params[:tournament_id])
      raise ActiveRecord::RecordNotFound unless can_manage_tournament?(@tournament)

      @category = @tournament.tournament_categories.find(params[:tournament_category_id])
    end
  end
end
