class VersionTournamentDraws < ActiveRecord::Migration[8.1]
  def change
    add_column :tournament_draws, :superseded_at, :datetime

    remove_index :tournament_draws, name: "index_tournament_draws_unique_category"
    add_index :tournament_draws,
      [:tournament_id, :tournament_category_id],
      unique: true,
      where: "superseded_at IS NULL",
      name: "index_active_tournament_draws_unique_category"

    remove_check_constraint :tournament_draws, name: "tournament_draws_entry_count_minimum"
    add_check_constraint :tournament_draws, "entry_count >= 1", name: "tournament_draws_entry_count_minimum"
  end
end
