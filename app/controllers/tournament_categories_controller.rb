class TournamentCategoriesController < ApplicationController
  before_action :set_tournament
  before_action :set_category, only: %i[show edit update]

  def index
    @categories = @tournament.tournament_categories.order(:name)
  end

  def show; end

  def new
    @category = @tournament.tournament_categories.build(event_type: "kyorugi")
  end

  def create
    @category = @tournament.tournament_categories.build(category_params)

    if @category.save
      redirect_to @tournament, notice: "Tournament category created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      redirect_to tournament_tournament_category_path(@tournament, @category), notice: "Tournament category updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def set_category
    @category = @tournament.tournament_categories.find(params[:id])
  end

  def category_params
    params.require(:tournament_category).permit(
      :event_type, :gender, :age_min, :age_max, :weight_min, :weight_max,
      :belt_min, :belt_max, :registration_fee
    )
  end
end
