require "test_helper"

class OrganizerMatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "matches-organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(name: "Matches Open", organizer: @organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    @category = @tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 18)
    3.times { |i| create_weight_verified_registration(tournament: @tournament, category: @category, email: "matches-#{i}@example.test") }
    BracketGenerator.new(@category).call
    @category.reload
    @match = @category.matches.find(&:ready_for_result?)
    sign_in_as @organizer
  end

  test "organizer records a points result across rounds and advances the winner" do
    patch organizer_match_path(@match), params: {
      match: {
        decision: "points",
        rounds: {
          "0" => { points_one: 6, points_two: 2 },
          "1" => { points_one: 3, points_two: 8 },
          "2" => { points_one: 5, points_two: 1 }
        }
      }
    }

    assert_redirected_to organizer_tournament_tournament_category_draw_path(@tournament, @category)
    @match.reload
    assert @match.completed?
    assert_equal @match.registration_one_id, @match.winner_registration_id
    assert_includes [ @match.next_match.registration_one_id, @match.next_match.registration_two_id ], @match.winner_registration_id
  end

  test "a tied round without a superiority pick is rejected" do
    patch organizer_match_path(@match), params: {
      match: {
        decision: "points",
        rounds: {
          "0" => { points_one: 4, points_two: 4 },
          "1" => { points_one: 3, points_two: 1 }
        }
      }
    }

    follow_redirect!
    assert_includes response.body, "superiority"
    assert_not @match.reload.completed?
  end

  test "organizer records a withdrawal without round scores" do
    patch organizer_match_path(@match), params: { match: { decision: "withdrawal", winner_side: "two" } }

    assert_redirected_to organizer_tournament_tournament_category_draw_path(@tournament, @category)
    @match.reload
    assert @match.completed?
    assert_equal "withdrawal", @match.decision
    assert_equal @match.registration_two_id, @match.winner_registration_id
  end

  test "non manager cannot record a result" do
    other = User.create!(name: "Other", email: "matches-other@example.test", password: "password123", role: :organizer)
    sign_in_as other

    patch organizer_match_path(@match), params: { match: { decision: "withdrawal", winner_side: "one" } }

    assert_response :not_found
  end
end
