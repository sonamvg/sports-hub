class CreateTournamentDrawMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_draw_matches do |t|
      t.references :tournament_draw, null: false, foreign_key: true
      t.references :red_registration, foreign_key: { to_table: :registrations }
      t.references :blue_registration, foreign_key: { to_table: :registrations }
      t.integer :red_source_match_position
      t.integer :blue_source_match_position
      t.integer :round_number, null: false
      t.integer :position, null: false
      t.boolean :bye, null: false, default: false

      t.timestamps
    end

    add_index :tournament_draw_matches, [:tournament_draw_id, :round_number, :position], unique: true, name: "index_draw_matches_unique_round_position"
    add_check_constraint :tournament_draw_matches, "round_number >= 1", name: "draw_matches_round_number_positive"
    add_check_constraint :tournament_draw_matches, "position >= 1", name: "draw_matches_position_positive"
  end
end
