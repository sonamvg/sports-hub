require "test_helper"

class TournamentCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
    @category = @tournament.tournament_categories.find_or_create_by!(
      event_type: "kyorugi",
      gender: "female",
      age_min: 12,
      age_max: 14,
      weight_min: 33,
      weight_max: 37
    )
    sign_in_as @organizer
  end

  test "lists tournament categories as read only defaults" do
    get tournament_tournament_categories_path(@tournament)

    assert_response :success
    assert_includes response.body, "This tournament uses PodiumCircle default categories."
    assert_includes response.body, @category.name
    assert_includes response.body, "View -&gt;"
    assert_no_match(/Add category/, response.body)
    assert_no_match(/Edit category/, response.body)
  end

  test "shows category details without edit action" do
    get tournament_tournament_category_path(@tournament, @category)

    assert_response :success
    assert_includes response.body, @category.name
    assert_includes response.body, "Back to categories"
    assert_no_match(/Edit category/, response.body)
  end

  test "organizer viewing the public category page gets a clear link to set the draw" do
    get tournament_tournament_category_path(@tournament, @category)

    assert_response :success
    assert_includes response.body, "YOU MANAGE THIS TOURNAMENT"
    assert_includes response.body, "Set the draw for this category"
    assert_includes response.body, organizer_tournament_tournament_category_draw_path(@tournament, @category)
    assert_includes response.body, "Weigh in athletes"
    assert_includes response.body, organizer_tournament_weight_checks_path(@tournament)
  end

  test "organizer viewing the public category page after a draw is generated sees a score-matches link" do
    draw_category = @tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 18)
    create_weight_verified_registration(tournament: @tournament, category: draw_category, email: "manager-banner-one@example.test")
    create_weight_verified_registration(tournament: @tournament, category: draw_category, email: "manager-banner-two@example.test")
    assert BracketGenerator.new(draw_category).call.success?

    get tournament_tournament_category_path(@tournament, draw_category)

    assert_response :success
    assert_includes response.body, "Score matches for this category"
  end

  test "category create route is not available" do
    assert_no_difference("@tournament.tournament_categories.count") do
      post tournament_tournament_categories_path(@tournament), params: {
        tournament_category: {
          event_type: "kyorugi",
          gender: "female",
          age_min: 12,
          age_max: 14,
          weight_max: 41
        }
      }
    end

    assert_response :not_found
  end

  test "category edit route is not available" do
    assert_raises(NoMethodError) do
      edit_tournament_tournament_category_path(@tournament, @category)
    end
  end

  test "signed out visitor sees a not-generated message when no draw exists yet" do
    delete logout_path

    get tournament_tournament_category_path(@tournament, @category)

    assert_response :success
    assert_includes response.body, "Draw not generated yet"
    assert_not_includes response.body, "brackets-viewer"
  end

  test "signed out visitor can see the bracket, next matches, and winners once a draw is generated" do
    draw_category = @tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 18)
    delete logout_path

    registration_one = create_weight_verified_registration(tournament: @tournament, category: draw_category, email: "public-draw-one@example.test")
    registration_two = create_weight_verified_registration(tournament: @tournament, category: draw_category, email: "public-draw-two@example.test")
    assert BracketGenerator.new(draw_category).call.success?
    match = draw_category.matches.sole

    get tournament_tournament_category_path(@tournament, draw_category)

    assert_response :success
    assert_includes response.body, "brackets-viewer"
    assert_includes response.body, "Next matches"
    assert_includes response.body, registration_one.athlete.full_name
    assert_includes response.body, registration_two.athlete.full_name
    assert_not_includes response.body, "Save result"

    winner_side = match.registration_one_id == registration_one.id ? "one" : "two"
    loser_side = winner_side == "one" ? "two" : "one"
    match.record_result!(winner_registration_id: registration_one.id, decision: :points, score_data: { "rounds_won" => { winner_side => 2, loser_side => 1 } })

    get tournament_tournament_category_path(@tournament, draw_category)

    assert_response :success
    assert_includes response.body, "Results so far"
    assert_includes response.body, "won 2-1 on points"
    assert_includes response.body, "Winners"
    assert_includes response.body, registration_one.athlete.full_name
  end
end
