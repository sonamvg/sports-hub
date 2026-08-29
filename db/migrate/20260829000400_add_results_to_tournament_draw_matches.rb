class AddResultsToTournamentDrawMatches < ActiveRecord::Migration[8.1]
  def change
    change_table :tournament_draw_matches, bulk: true do |t|
      t.references :winner_registration, foreign_key: { to_table: :registrations }
      t.integer :red_round_1_points
      t.integer :blue_round_1_points
      t.integer :red_round_2_points
      t.integer :blue_round_2_points
      t.integer :red_round_3_points
      t.integer :blue_round_3_points
      t.string :red_head_guard_color, null: false, default: "red"
      t.string :blue_head_guard_color, null: false, default: "blue"
      t.datetime :completed_at
      t.references :completed_by, foreign_key: { to_table: :users }
    end

    add_check_constraint :tournament_draw_matches, "red_round_1_points IS NULL OR red_round_1_points >= 0", name: "draw_matches_red_round_1_points_nonnegative"
    add_check_constraint :tournament_draw_matches, "blue_round_1_points IS NULL OR blue_round_1_points >= 0", name: "draw_matches_blue_round_1_points_nonnegative"
    add_check_constraint :tournament_draw_matches, "red_round_2_points IS NULL OR red_round_2_points >= 0", name: "draw_matches_red_round_2_points_nonnegative"
    add_check_constraint :tournament_draw_matches, "blue_round_2_points IS NULL OR blue_round_2_points >= 0", name: "draw_matches_blue_round_2_points_nonnegative"
    add_check_constraint :tournament_draw_matches, "red_round_3_points IS NULL OR red_round_3_points >= 0", name: "draw_matches_red_round_3_points_nonnegative"
    add_check_constraint :tournament_draw_matches, "blue_round_3_points IS NULL OR blue_round_3_points >= 0", name: "draw_matches_blue_round_3_points_nonnegative"
    add_check_constraint :tournament_draw_matches, "red_head_guard_color IN ('red', 'blue')", name: "draw_matches_red_head_guard_color_valid"
    add_check_constraint :tournament_draw_matches, "blue_head_guard_color IN ('red', 'blue')", name: "draw_matches_blue_head_guard_color_valid"
    add_check_constraint :tournament_draw_matches, "red_head_guard_color <> blue_head_guard_color", name: "draw_matches_head_guard_colors_distinct"
  end
end
