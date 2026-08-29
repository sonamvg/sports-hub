class AddRoundDecisionsToTournamentDrawMatches < ActiveRecord::Migration[8.1]
  def change
    change_table :tournament_draw_matches, bulk: true do |t|
      t.string :round_1_winner_side
      t.string :round_2_winner_side
      t.string :round_3_winner_side
    end

    add_check_constraint :tournament_draw_matches, "round_1_winner_side IS NULL OR round_1_winner_side IN ('red', 'blue')", name: "draw_matches_round_1_winner_side_valid"
    add_check_constraint :tournament_draw_matches, "round_2_winner_side IS NULL OR round_2_winner_side IN ('red', 'blue')", name: "draw_matches_round_2_winner_side_valid"
    add_check_constraint :tournament_draw_matches, "round_3_winner_side IS NULL OR round_3_winner_side IN ('red', 'blue')", name: "draw_matches_round_3_winner_side_valid"
  end
end
