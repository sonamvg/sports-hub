require "test_helper"

class TournamentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Demo Organizer", email: "organizer@example.com", password: "password123", role: :organizer)
    sign_in_as @organizer
  end

  test "new tournament form includes required setup fields" do
    get new_tournament_path

    assert_response :success
    [
      "Tournament name",
      "Tournament level",
      "Organising organisation",
      "Start date",
      "End date",
      "Registration opens at",
      "Registration closes at",
      "Time zone",
      "Venue",
      "Primary contact",
      "Competition formats",
      "Basic eligibility",
      "Category generation",
      "Registration capacity",
      "Fee",
      "Currency",
      "Required documents",
      "Refund policy",
      "Logo or image upload",
      "Banner or hero image upload",
      "Save as Draft",
      "Publish"
    ].each do |label|
      assert_includes response.body, label
    end
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
          tournament_level: "State",
          organizing_organization: "Maharashtra Taekwondo Association",
          time_zone: "Mumbai",
          registration_opens_at: "2026-10-01T09:00",
          registration_closes_at: "2026-11-25T18:00",
          primary_contact_name: "Event Desk",
          primary_contact_email: "events@example.com",
          primary_contact_phone: "9876543210",
          competition_formats: "Kyorugi, Poomsae",
          eligibility_summary: "Red belt and above",
          category_generation_method: "Auto-generate from eligibility rules",
          registration_capacity: 400,
          registration_fee: "1500.00",
          currency: "inr",
          required_documents: "Age proof, association ID",
          refund_policy: "Refunds close 7 days before event",
          status: "registration_open",
          website_url: "https://example.com/pune-invitational",
          logo_image: tournament_image_upload,
          banner_image: tournament_image_upload,
          organizer_user_ids: [collaborator.id]
        }
      }
    end

    tournament = Tournament.order(:created_at).last
    assert_redirected_to tournament_path(tournament)
    assert_equal @organizer, tournament.organizer
    assert_equal "registration_open", tournament.status
    assert_equal "https://example.com/pune-invitational", tournament.website_url
    assert_predicate tournament.logo_image, :attached?
    assert_predicate tournament.banner_image, :attached?
    assert_equal "State", tournament.tournament_level
    assert_equal "Maharashtra Taekwondo Association", tournament.organizing_organization
    assert_equal "Mumbai", tournament.time_zone
    assert_equal "events@example.com", tournament.primary_contact_email
    assert_equal "Kyorugi, Poomsae", tournament.competition_formats
    assert_equal "Auto-generate from eligibility rules", tournament.category_generation_method
    assert_equal 400, tournament.registration_capacity
    assert_equal BigDecimal("1500.0"), tournament.registration_fee
    assert_equal "INR", tournament.currency
    assert_equal @organizer, tournament.tournament_organizers.super_organizer.sole.user
    assert_includes tournament.organizer_users, collaborator
  end

  test "publish button moves draft tournament to scheduled" do
    assert_difference("Tournament.count", 1) do
      post tournaments_path, params: {
        commit: "Publish",
        tournament: {
          name: "Pune Invitational",
          start_date: "2026-12-05",
          end_date: "2026-12-06",
          status: "draft"
        }
      }
    end

    assert_predicate Tournament.order(:created_at).last, :scheduled?
  end

  test "save as draft button keeps tournament in draft" do
    assert_difference("Tournament.count", 1) do
      post tournaments_path, params: {
        commit: "Save as Draft",
        tournament: {
          name: "Draft Invitational",
          start_date: "2026-12-05",
          end_date: "2026-12-06",
          status: "registration_open"
        }
      }
    end

    assert_predicate Tournament.order(:created_at).last, :draft?
  end

  test "pending organizer cannot create tournament" do
    pending = User.create!(
      name: "Pending Organizer",
      email: "pending-organizer@example.test",
      password: "password123",
      role: :organizer,
      organizer_status: :pending,
      phone: "9876543210",
      organizer_designation: "Event Director",
      identity_document: identity_document_upload
    )
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
          website_url: "not-a-url"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Website url must be a valid http or https URL"
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
      end_date: Date.new(2026, 12, 6),
      primary_contact_name: "Event Desk",
      primary_contact_email: "private-contact@example.com",
      primary_contact_phone: "9876543210"
    )
    tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    delete logout_path

    get tournament_path(tournament)

    assert_response :success
    assert_includes response.body, "Pune Invitational"
    assert_includes response.body, "Categories"
    assert_includes response.body, "category-list"
    assert_includes response.body, "category-row"
    assert_not_includes response.body, "My athletes"
    assert_not_includes response.body, "No athlete profiles yet"
    assert_not_includes response.body, "Register athlete"
    assert_not_includes response.body, "Register →"
    assert_not_includes response.body, "Add athlete"
    assert_not_includes response.body, "private-contact@example.com"
    assert_not_includes response.body, "9876543210"
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

  test "index renders uploaded tournament logos and website links" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      website_url: "https://example.com/pune-invitational"
    )
    tournament.logo_image.attach(tournament_image_upload)

    get tournaments_path

    assert_response :success
    assert_includes response.body, "#{tournament.name} logo"
    assert_includes response.body, "/rails/active_storage"
    assert_includes response.body, "https://example.com/pune-invitational"
  end

  test "show renders uploaded tournament banner" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
    tournament.banner_image.attach(tournament_image_upload)

    get tournament_path(tournament)

    assert_response :success
    assert_includes response.body, "#{tournament.name} banner"
    assert_includes response.body, "/rails/active_storage"
  end
end
