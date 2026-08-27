class TournamentCategoriesController < ApplicationController
  before_action :require_user, except: %i[index show]
  before_action :set_tournament
  before_action :require_tournament_manager, except: %i[index show]
  before_action :require_category_editor, only: %i[new create create_defaults edit update]
  before_action :set_category, only: %i[show edit update]

  def index
    @categories = @tournament.tournament_categories.order(:name)
    @default_templates = TournamentCategory::DEFAULT_CATEGORY_TEMPLATES
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

  def create_defaults
    selected_templates = Array(params[:template_keys]).filter_map { |key| TournamentCategory.default_template_for(key) }
    created_count = 0

    selected_templates.each do |template|
      category = @tournament.tournament_categories.find_or_initialize_by(template.except(:key))
      created_count += 1 if category.new_record? && category.save
    end

    if created_count.positive?
      redirect_to tournament_tournament_categories_path(@tournament), notice: "#{created_count} default categories added."
    else
      redirect_to tournament_tournament_categories_path(@tournament), alert: "Select at least one new default category."
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

  def require_tournament_manager
    raise ActiveRecord::RecordNotFound unless can_manage_tournament?(@tournament)
  end

  def require_category_editor
    return if can_edit_tournament_categories?(@tournament)

    redirect_to tournament_tournament_categories_path(@tournament), alert: "Categories can be edited only before registration starts."
  end

  def category_params
    params.require(:tournament_category).permit(
      :event_type, :gender, :age_min, :age_max, :weight_min, :weight_max,
      :belt_min, :belt_max
    )
  end
end
