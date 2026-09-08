require "test_helper"

class OrganizerDrawsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "draw-organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(name: "Draw Open", organizer: @organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    @category = @tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 18)
    sign_in_as @organizer
  end

  test "show renders the eligible athlete count before a draw exists" do
    create_weight_verified_registration(tournament: @tournament, category: @category, email: "draw-show-1@example.test")
    create_weight_verified_registration(tournament: @tournament, category: @category, email: "draw-show-2@example.test")

    get organizer_tournament_tournament_category_draw_path(@tournament, @category)

    assert_response :success
    assert_includes response.body, "2 athletes"
  end

  test "organizer can generate a draw which locks weight checks" do
    3.times { |i| create_weight_verified_registration(tournament: @tournament, category: @category, email: "draw-gen-#{i}@example.test") }

    post organizer_tournament_tournament_category_draw_path(@tournament, @category)

    assert_redirected_to organizer_tournament_tournament_category_draw_path(@tournament, @category)
    @category.reload
    assert @category.draw_generated?
    assert_equal 3, @category.matches.count
  end

  test "regenerating is refused once a result has been recorded" do
    3.times { |i| create_weight_verified_registration(tournament: @tournament, category: @category, email: "draw-lock-#{i}@example.test") }
    BracketGenerator.new(@category).call
    @category.reload
    real_match = @category.matches.find(&:ready_for_result?)
    real_match.record_result!(winner_registration_id: real_match.registration_one_id, decision: :points, score_data: {})

    post organizer_tournament_tournament_category_draw_path(@tournament, @category)

    follow_redirect!
    assert_includes response.body, "locked"
    assert_equal 3, @category.matches.count
  end

  test "show displays a locked, read-only points table for completed matches" do
    3.times { |i| create_weight_verified_registration(tournament: @tournament, category: @category, email: "draw-completed-#{i}@example.test") }
    BracketGenerator.new(@category).call
    @category.reload
    real_match = @category.matches.find(&:ready_for_result?)
    real_match.record_result!(
      winner_registration_id: real_match.registration_one_id,
      decision: :points,
      score_data: {
        "rounds" => [
          { "round" => 1, "points_one" => 21, "points_two" => 15, "round_winner" => "one" },
          { "round" => 2, "points_one" => 18, "points_two" => 20, "round_winner" => "two" },
          { "round" => 3, "points_one" => 22, "points_two" => 19, "round_winner" => "one" }
        ],
        "rounds_won" => { "one" => 2, "two" => 1 }
      }
    )

    get organizer_tournament_tournament_category_draw_path(@tournament, @category)

    assert_response :success
    assert_includes response.body, "Completed matches"
    assert_includes response.body, "Locked"
    assert_includes response.body, "won 2-1 on points"
    assert_includes response.body, "21"
    assert_includes response.body, "15"
    assert_includes response.body, "18"
    assert_includes response.body, "20"

    completed_section = response.body[response.body.index("Completed matches")..]
    assert_no_match(/<input[^>]*type="number"/, completed_section)
    assert_no_match(/<form/, completed_section)

    # the completed match must no longer appear in the editable "ready for scoring" list
    ready_section = response.body[response.body.index("Matches ready for scoring")...response.body.index("Completed matches")]
    assert_not_includes ready_section, "Round 1 &middot; Match #{real_match.slot_position}"
  end

  test "non manager cannot view the draw" do
    other = User.create!(name: "Other", email: "draw-other@example.test", password: "password123", role: :organizer)
    sign_in_as other

    get organizer_tournament_tournament_category_draw_path(@tournament, @category)

    assert_response :not_found
  end
end
