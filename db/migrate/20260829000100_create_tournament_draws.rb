class CreateTournamentDraws < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_draws do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :tournament_category, null: false, foreign_key: true
      t.references :generated_by, null: false, foreign_key: { to_table: :users }
      t.integer :bracket_size, null: false
      t.integer :round_count, null: false
      t.integer :entry_count, null: false
      t.datetime :generated_at, null: false

      t.timestamps
    end

    add_index :tournament_draws, [:tournament_id, :tournament_category_id], unique: true, name: "index_tournament_draws_unique_category"
    add_check_constraint :tournament_draws, "bracket_size >= 2", name: "tournament_draws_bracket_size_minimum"
    add_check_constraint :tournament_draws, "round_count >= 1", name: "tournament_draws_round_count_minimum"
    add_check_constraint :tournament_draws, "entry_count >= 2", name: "tournament_draws_entry_count_minimum"
  end
end
