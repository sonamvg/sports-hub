require "test_helper"

class TournamentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Demo Organizer", email: "organizer@example.com", password: "password123", role: :organizer)
    sign_in_as @organizer
  end

  test "creates tournament" do
    assert_difference("Tournament.count", 1) do
      post tournaments_path, params: {
        tournament: {
          name: "Pune Invitational",
          venue: "Balewadi Sports Complex",
          city: "Pune",
          state: "Maharashtra",
          start_date: "2026-12-05",
          end_date: "2026-12-06",
          status: "registration_open"
        }
      }
    end

    tournament = Tournament.order(:created_at).last
    assert_redirected_to tournament_path(tournament)
    assert_equal @organizer, tournament.organizer
    assert_equal "registration_open", tournament.status
  end

  test "renders errors when tournament is invalid" do
    assert_no_difference("Tournament.count") do
      post tournaments_path, params: { tournament: { name: "", start_date: "2026-12-06", end_date: "2026-12-05" } }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "End date cannot be before start date"
  end

  test "updates tournament" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )

    patch tournament_path(tournament), params: {
      tournament: {
        name: "Pune Invitational Championship",
        venue: "Balewadi Sports Complex",
        city: "Pune",
        state: "Maharashtra",
        start_date: "2026-12-07",
        end_date: "2026-12-08",
        status: "registration_open"
      }
    }

    assert_redirected_to tournament_path(tournament)
    tournament.reload
    assert_equal "Pune Invitational Championship", tournament.name
    assert_equal "Balewadi Sports Complex", tournament.venue
    assert_equal Date.new(2026, 12, 7), tournament.start_date
    assert_equal "registration_open", tournament.status
  end

  test "renders errors when update is invalid" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )

    patch tournament_path(tournament), params: {
      tournament: {
        name: "Pune Invitational",
        start_date: "2026-12-09",
        end_date: "2026-12-08"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "End date cannot be before start date"
  end

  test "show lists current user's athletes under tournament" do
    parent = User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :parent)
    athlete = parent.athletes.create!(
      first_name: "Aarohi",
      last_name: "Shah",
      date_of_birth: Date.new(2014, 5, 12),
      gender: "female",
      belt: "red",
      weight: 39.5
    )
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, registered_weight: 39.5, status: :approved)
    sign_in_as parent

    get tournament_path(tournament)

    assert_response :success
    assert_includes response.body, "My athletes"
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, "Approved"
    assert_includes response.body, category.name
  end
end
