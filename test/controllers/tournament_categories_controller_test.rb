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
    sign_in_as @organizer
  end

  test "creates category" do
    assert_difference("@tournament.tournament_categories.count", 1) do
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

    assert_redirected_to tournament_path(@tournament)
    category = @tournament.tournament_categories.order(:created_at).last
    assert_equal "Kyorugi Female Age 12-14 U41", category.name
    assert_equal "female", category.gender
  end

  test "creates selected default categories" do
    assert_difference("@tournament.tournament_categories.count", 2) do
      post create_defaults_tournament_tournament_categories_path(@tournament), params: {
        template_keys: ["cadet-female-u37", "cadet-male-u37"]
      }
    end

    assert_redirected_to tournament_tournament_categories_path(@tournament)
    assert_equal "2 default categories added.", flash[:notice]
    assert_includes @tournament.tournament_categories.pluck(:name), "Kyorugi Female Age 12-14 33-37kg"
    assert_includes @tournament.tournament_categories.pluck(:name), "Kyorugi Male Age 12-14 33-37kg"
  end

  test "default category import skips existing categories" do
    @tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)

    assert_no_difference("@tournament.tournament_categories.count") do
      post create_defaults_tournament_tournament_categories_path(@tournament), params: {
        template_keys: ["cadet-female-u37"]
      }
    end

    assert_redirected_to tournament_tournament_categories_path(@tournament)
    assert_equal "Select at least one new default category.", flash[:alert]
  end

  test "renders errors when category is invalid" do
    assert_no_difference("@tournament.tournament_categories.count") do
      post tournament_tournament_categories_path(@tournament), params: {
        tournament_category: {
          event_type: "",
          age_min: 15,
          age_max: 12
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Event type can&#39;t be blank"
    assert_includes response.body, "Age max cannot be below minimum age"
  end

  test "updates category" do
    category = @tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    patch tournament_tournament_category_path(@tournament, category), params: {
      tournament_category: {
        event_type: "kyorugi",
        gender: "female",
        age_min: 12,
        age_max: 14,
        weight_max: 44
      }
    }

    assert_redirected_to tournament_tournament_category_path(@tournament, category)
    category.reload
    assert_equal "Kyorugi Female Age 12-14 U44", category.name
    assert_equal 44, category.weight_max
  end

  test "renders errors when update is invalid" do
    category = @tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    patch tournament_tournament_category_path(@tournament, category), params: {
      tournament_category: {
        event_type: "kyorugi",
        weight_min: 45,
        weight_max: 41
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Weight max cannot be below minimum weight"
  end
end
