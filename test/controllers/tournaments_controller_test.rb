require "test_helper"

class TournamentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Demo Organizer", email: "organizer@example.com", password: "password123", role: :organizer)
    sign_in_as @organizer
  end

  test "creates tournament" do
    collaborator = User.create!(name: "Second Organizer", email: "second-organizer@example.test", password: "password123", role: :organizer)

    assert_difference("Tournament.count", 1) do
      post tournaments_path, params: {
        tournament: {
          name: "Pune Invitational",
          venue: "Balewadi Sports Complex",
          city: "Pune",
          state: "Maharashtra",
          start_date: "2026-12-05",
          end_date: "2026-12-06",
          status: "registration_open",
          website_url: "https://example.com/pune-invitational",
          logo_url: "https://example.com/pune-logo.png",
          organizer_user_ids: [collaborator.id]
        }
      }
    end

    tournament = Tournament.order(:created_at).last
    assert_redirected_to tournament_path(tournament)
    assert_equal @organizer, tournament.organizer
    assert_equal "registration_open", tournament.status
    assert_equal "https://example.com/pune-invitational", tournament.website_url
    assert_equal "https://example.com/pune-logo.png", tournament.logo_url
    assert_equal @organizer, tournament.tournament_organizers.super_organizer.sole.user
    assert_includes tournament.organizer_users, collaborator
  end

  test "pending organizer cannot create tournament" do
    pending = User.create!(name: "Pending Organizer", email: "pending-organizer@example.test", password: "password123", role: :organizer, organizer_status: :pending)
    sign_in_as pending

    assert_no_difference("Tournament.count") do
      post tournaments_path, params: {
        tournament: {
          name: "Pending Open",
          start_date: "2026-12-05",
          end_date: "2026-12-06"
        }
      }
    end

    assert_redirected_to organizers_path
    assert_equal "Super admin verification is required before creating tournaments.", flash[:alert]
  end

  test "renders errors when tournament is invalid" do
    assert_no_difference("Tournament.count") do
      post tournaments_path, params: { tournament: { name: "", start_date: "2026-12-06", end_date: "2026-12-05" } }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "End date cannot be before start date"
  end

  test "renders errors when tournament branding urls are invalid" do
    assert_no_difference("Tournament.count") do
      post tournaments_path, params: {
        tournament: {
          name: "Pune Invitational",
          start_date: "2026-12-05",
          end_date: "2026-12-06",
          website_url: "not-a-url",
          logo_url: "ftp://example.com/logo.png"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Website url must be a valid http or https URL"
    assert_includes response.body, "Logo url must be a valid http or https URL"
  end

  test "updates tournament" do
    collaborator = User.create!(name: "Second Organizer", email: "second-organizer-update@example.test", password: "password123", role: :organizer)
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
        status: "registration_open",
        organizer_user_ids: [collaborator.id]
      }
    }

    assert_redirected_to tournament_path(tournament)
    tournament.reload
    assert_equal "Pune Invitational Championship", tournament.name
    assert_equal "Balewadi Sports Complex", tournament.venue
    assert_equal Date.new(2026, 12, 7), tournament.start_date
    assert_equal "registration_open", tournament.status
    assert_includes tournament.organizer_users, collaborator
  end

  test "tournament collaborator can edit tournament" do
    collaborator = User.create!(name: "Collaborator", email: "collaborator@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
    tournament.tournament_organizers.create!(user: collaborator, added_by: @organizer)
    sign_in_as collaborator

    get edit_tournament_path(tournament)

    assert_response :success
    assert_includes response.body, "Edit tournament"
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

  test "logged out show hides athlete-specific registration sections" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
    tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    delete logout_path

    get tournament_path(tournament)

    assert_response :success
    assert_includes response.body, "Pune Invitational"
    assert_includes response.body, "Categories"
    assert_not_includes response.body, "My athletes"
    assert_not_includes response.body, "No athlete profiles yet"
    assert_not_includes response.body, "Register athlete"
    assert_not_includes response.body, "Register →"
    assert_not_includes response.body, "Add athlete"
  end

  test "logged in show keeps athlete registration actions" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
    tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    get tournament_path(tournament)

    assert_response :success
    assert_includes response.body, "My athletes"
    assert_includes response.body, "No athlete profiles yet"
    assert_includes response.body, "Register athlete"
  end

  test "show renders tournament breadcrumbs" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )

    get tournament_path(tournament)

    assert_response :success
    assert_includes response.body, 'aria-label="Breadcrumb"'
    assert_includes response.body, "Home"
    assert_includes response.body, "Tournaments"
    assert_includes response.body, "Pune Invitational"
  end

  test "index renders tournament logos and website links" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      website_url: "https://example.com/pune-invitational",
      logo_url: "https://example.com/pune-logo.png"
    )

    get tournaments_path

    assert_response :success
    assert_includes response.body, "#{tournament.name} logo"
    assert_includes response.body, "https://example.com/pune-logo.png"
    assert_includes response.body, "https://example.com/pune-invitational"
  end
end
