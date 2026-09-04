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

  test "non manager cannot view the draw" do
    other = User.create!(name: "Other", email: "draw-other@example.test", password: "password123", role: :organizer)
    sign_in_as other

    get organizer_tournament_tournament_category_draw_path(@tournament, @category)

    assert_response :not_found
  end
end
