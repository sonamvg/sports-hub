class AddDrawGeneratedAtToTournamentCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :tournament_categories, :draw_generated_at, :datetime
  end
end
