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
    @category = @tournament.tournament_categories.create!(
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
    assert_includes response.body, "This tournament uses Sports Hub default categories."
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
end
