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
      "Fee per category",
      "Currency",
      "Required documents",
      "Refund policy",
      "Logo or image upload",
      "Banner or hero image upload",
      "Kyorugi",
      "Individual Poomsae",
      "Age proof required",
      "Government identity proof",
      "Full refund before registration closes",
      "Enter competition format",
      "Enter eligibility rule",
      "Enter required document",
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
          competition_format_options: ["Kyorugi", "Individual Poomsae"],
          competition_format_other: ["Breaking"],
          eligibility_options: ["Age proof required"],
          eligibility_other: ["Red belt and above", "State ranking required"],
          category_generation_method: "Auto-generate from eligibility rules",
          registration_capacity: 400,
          registration_fee: "1500.00",
          currency: "inr",
          required_document_options: ["Age proof", "Association ID"],
          required_document_other: ["Coach approval"],
          refund_policy_options: ["Full refund before registration closes", "No refund after draws are published"],
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
    assert_equal "Kyorugi, Individual Poomsae, Breaking", tournament.competition_formats
    assert_equal "Age proof required, Red belt and above, State ranking required", tournament.eligibility_summary
    assert_equal "Auto-generate from eligibility rules", tournament.category_generation_method
    assert_equal 400, tournament.registration_capacity
    assert_equal BigDecimal("1500.0"), tournament.registration_fee
    assert_equal "INR", tournament.currency
    assert_equal "Age proof, Association ID, Coach approval", tournament.required_documents
    assert_equal "Full refund before registration closes, No refund after draws are published", tournament.refund_policy
    assert_equal @organizer, tournament.tournament_organizers.super_organizer.sole.user
    assert_includes tournament.organizer_users, collaborator
  end

  test "creates checked default categories during auto generation" do
    assert_difference("TournamentCategory.count", 1) do
      post tournaments_path, params: {
        commit: "Publish",
        tournament: {
          name: "Auto Category Open",
          start_date: "2026-12-05",
          end_date: "2026-12-06",
          category_generation_method: "Auto-generate from eligibility rules",
          default_category_templates: {
            "0" => {
              selected: "1",
              event_type: "kyorugi",
              gender: "female",
              age_min: "12",
              age_max: "14",
              weight_min: "33",
              weight_max: "37"
            },
            "1" => {
              event_type: "kyorugi",
              gender: "male",
              age_min: "12",
              age_max: "14",
              weight_min: "33",
              weight_max: "37"
            }
          }
        }
      }
    end

    tournament = Tournament.order(:created_at).last
    assert_equal ["Kyorugi Female Age 12-14 33-37kg"], tournament.tournament_categories.pluck(:name)
  end

  test "creates manual categories from tournament form" do
    assert_difference("TournamentCategory.count", 1) do
      post tournaments_path, params: {
        commit: "Publish",
        tournament: {
          name: "Manual Category Open",
          start_date: "2026-12-05",
          end_date: "2026-12-06",
          category_generation_method: "Manual categories",
          manual_categories: {
            "0" => {
              event_type: "kyorugi",
              gender: "male",
              age_min: "15",
              age_max: "17",
              weight_max: "55"
            }
          }
        }
      }
    end

    tournament = Tournament.order(:created_at).last
    assert_equal ["Kyorugi Male Age 15-17 U55"], tournament.tournament_categories.pluck(:name)
  end

  test "imports categories from csv during tournament form save" do
    assert_difference("TournamentCategory.count", 1) do
      post tournaments_path, params: {
        commit: "Publish",
        tournament: {
          name: "Import Category Open",
          start_date: "2026-12-05",
          end_date: "2026-12-06",
          category_generation_method: "Import categories",
          category_import_file: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/categories.csv"), "text/csv")
        }
      }
    end

    tournament = Tournament.order(:created_at).last
    assert_equal ["Kyorugi Female Age 12-14 33-37kg Red-Black"], tournament.tournament_categories.pluck(:name)
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

  test "tournament form can invite new organizer by email" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )

    assert_difference("TournamentOrganizerInvitation.count", 1) do
      patch tournament_path(tournament), params: {
        tournament: {
          name: "Pune Invitational",
          start_date: "2026-12-05",
          end_date: "2026-12-06",
          invite_organizer_email: "new-organizer@example.test"
        }
      }
    end

    assert_redirected_to tournament_path(tournament)
    invitation = TournamentOrganizerInvitation.order(:created_at).last
    assert_equal tournament, invitation.tournament
    assert_equal @organizer, invitation.invited_by
    assert_equal "new-organizer@example.test", invitation.email
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

  test "show lists current user's registered athletes under tournament" do
    parent = User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :parent)
    other_parent = User.create!(name: "Other Parent", email: "other-parent@example.com", password: "password123", role: :parent)
    athlete = parent.athletes.create!(
      first_name: "Aarohi",
      last_name: "Shah",
      date_of_birth: Date.new(2014, 5, 12),
      gender: "female",
      belt: "red",
      weight: 39.5
    )
    other_athlete = other_parent.athletes.create!(
      first_name: "Hidden",
      last_name: "Athlete",
      date_of_birth: Date.new(2013, 4, 10),
      gender: "male",
      belt: "blue",
      weight: 45
    )
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, registered_weight: 39.5, status: :approved, payment_receipt: payment_receipt_upload)
    tournament.registrations.create!(athlete: other_athlete, tournament_category: category, registered_weight: 45, status: :pending, payment_receipt: payment_receipt_upload)
    sign_in_as parent

    get tournament_path(tournament)

    assert_response :success
    assert_includes response.body, "Registered athletes"
    assert_includes response.body, "registered-athlete-list"
    assert_includes response.body, "registered-athlete-row"
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, "Approved"
    assert_includes response.body, category.name
    assert_not_includes response.body, "Hidden Athlete"
  end

  test "tournament manager sees all registered athletes" do
    parent = User.create!(name: "Demo Parent", email: "manager-parent@example.com", password: "password123", role: :parent)
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
    tournament.registrations.create!(athlete: athlete, tournament_category: category, registered_weight: 39.5, status: :approved, payment_receipt: payment_receipt_upload)

    get tournament_path(tournament)

    assert_response :success
    assert_includes response.body, "Registered athletes"
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, "39.5 kg"
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
    assert_not_includes response.body, "Registered athletes"
    assert_not_includes response.body, "No athlete profiles yet"
    assert_not_includes response.body, "Register athlete"
    assert_not_includes response.body, "Register →"
    assert_not_includes response.body, "Add athlete"
    assert_not_includes response.body, "private-contact@example.com"
    assert_not_includes response.body, "9876543210"
  end

  test "organizer show hides category registration actions" do
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
    assert_includes response.body, "Registered athletes"
    assert_includes response.body, "No registered athletes yet"
    assert_not_includes response.body, "Register athlete"
    assert_not_includes response.body, "Register →"
  end

  test "organizer sidebar lists tournament operation links" do
    tournament = Tournament.create!(
      name: "Sidebar Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )

    get tournaments_path

    assert_response :success
    assert_includes response.body, "My tournaments"
    assert_includes response.body, "Sidebar Invitational"
    assert_includes response.body, edit_tournament_path(tournament)
    assert_includes response.body, tournament_tournament_referees_path(tournament)
    assert_includes response.body, venue_setup_tournament_path(tournament)
    assert_includes response.body, organizer_tournament_weight_checks_path(tournament)
    assert_includes response.body, "Set draw"
  end

  test "show uses placeholder dashes for missing optional tournament data" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )

    get tournament_path(tournament)

    assert_response :success
    assert_includes response.body, "<span>--</span>"
    assert_not_includes response.body, "Not set"
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

  test "signed in users see register link for open tournaments on index" do
    athlete_user = User.create!(name: "Athlete User", email: "register-index-athlete@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as athlete_user

    tournament = Tournament.create!(
      name: "Open Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )

    get tournaments_path

    assert_response :success
    assert_includes response.body, new_tournament_registration_path(tournament)
    assert_includes response.body, "Register"
  end

  test "organizer does not see register link for tournaments on index" do
    tournament = Tournament.create!(
      name: "Open Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )

    get tournaments_path

    assert_response :success
    assert_includes response.body, tournament.name
    assert_not_includes response.body, new_tournament_registration_path(tournament)
    assert_not_includes response.body, ">Register</a>"
  end

  test "index filters tournaments by country and state" do
    matching = Tournament.create!(
      name: "Pune State Open",
      organizer: @organizer,
      status: :registration_open,
      city: "Pune",
      state: "Maharashtra",
      country: "India",
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
    Tournament.create!(
      name: "Dubai Open",
      organizer: @organizer,
      city: "Dubai",
      state: "Dubai",
      country: "UAE",
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )

    get tournaments_path(country: "India", state: "Maharashtra")

    assert_response :success
    assert_includes response.body, matching.name
    assert_equal 1, response.body.scan('class="entity-card tournament-card"').size
    assert_includes response.body, "Tournament filters"
    assert_includes response.body, "2 filters active"
    assert_includes response.body, "Apply filters"
    assert_includes response.body, "All countries"
    assert_includes response.body, "All states"
    assert_includes response.body, "Country"
    assert_includes response.body, "State"
  end

  test "index orders newest active tournaments before ended tournaments" do
    ended = Tournament.create!(
      name: "Ended Open",
      organizer: @organizer,
      status: :completed,
      start_date: 20.days.ago.to_date,
      end_date: 18.days.ago.to_date
    )
    older_active = Tournament.create!(
      name: "Older Active",
      organizer: @organizer,
      status: :registration_open,
      start_date: 10.days.from_now.to_date,
      end_date: 11.days.from_now.to_date
    )
    newer_active = Tournament.create!(
      name: "Newer Active",
      organizer: @organizer,
      status: :registration_open,
      start_date: 20.days.from_now.to_date,
      end_date: 21.days.from_now.to_date
    )

    get tournaments_path

    assert_response :success
    assert_operator response.body.index(newer_active.name), :<, response.body.index(older_active.name)
    assert_operator response.body.index(older_active.name), :<, response.body.index(ended.name)
  end

  test "index paginates tournaments" do
    13.times do |index|
      Tournament.create!(
        name: "Paged Tournament #{index}",
        organizer: @organizer,
        start_date: (index + 1).days.from_now.to_date,
        end_date: (index + 2).days.from_now.to_date
      )
    end

    get tournaments_path

    assert_response :success
    assert_includes response.body, "Page 1 of 2"
  end

  test "index renders placeholder for tournament without logo" do
    Tournament.create!(
      name: "Placeholder Open",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )

    get tournaments_path

    assert_response :success
    assert_includes response.body, "fallback-placeholder"
    assert_includes response.body, ">P</div>"
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

  test "show renders placeholder for tournament without banner" do
    tournament = Tournament.create!(
      name: "Placeholder Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )

    get tournament_path(tournament)

    assert_response :success
    assert_includes response.body, "P banner"
    assert_includes response.body, "fallback-placeholder"
  end

  test "public tournament pages do not expose bank account details" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      payment_account_name: "Pune Taekwondo Association",
      payment_bank_name: "Demo Bank",
      payment_account_number: "1234567890",
      payment_ifsc: "DEMO0001234",
      payment_instructions: "Use athlete name as reference"
    )
    delete logout_path

    get tournament_path(tournament)

    assert_response :success
    assert_not_includes response.body, "1234567890"
    assert_not_includes response.body, "DEMO0001234"
    assert_not_includes response.body, "Demo Bank"
    assert_not_includes response.body, "Use athlete name as reference"
  end

  test "public tournament page shows referee count without contact details" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
    tournament.tournament_referees.create!(name: "Meera Rao", phone: "9876543210")
    delete logout_path

    get tournament_path(tournament)

    assert_response :success
    assert_includes response.body, "1 referee"
    assert_not_includes response.body, "9876543210"
  end

  test "venue setup opens after registration closes" do
    tournament = Tournament.create!(
      name: "Closed Venue Open",
      organizer: @organizer,
      status: :registration_open,
      registration_opens_at: 10.days.ago,
      registration_closes_at: 1.day.ago,
      start_date: 2.days.from_now.to_date,
      end_date: 3.days.from_now.to_date
    )

    get venue_setup_tournament_path(tournament)
    assert_response :success
    assert_includes response.body, "Number of courts"

    patch venue_setup_tournament_path(tournament), params: { tournament: { courts_count: 4 } }

    assert_redirected_to tournament_path(tournament)
    assert_equal 4, tournament.reload.courts_count
  end

  test "venue setup is blocked before registration closes" do
    tournament = Tournament.create!(
      name: "Open Venue Open",
      organizer: @organizer,
      status: :registration_open,
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now,
      start_date: 2.days.from_now.to_date,
      end_date: 3.days.from_now.to_date
    )

    get venue_setup_tournament_path(tournament)

    assert_redirected_to tournament_path(tournament)
    assert_equal "Venue setup opens after registration closes.", flash[:alert]
  end

  test "set draw locks tournament after registration closes" do
    tournament = Tournament.create!(
      name: "Closed Draw Open",
      organizer: @organizer,
      status: :registration_open,
      registration_opens_at: 10.days.ago,
      registration_closes_at: 1.day.ago,
      start_date: 2.days.from_now.to_date,
      end_date: 3.days.from_now.to_date
    )

    patch set_draw_tournament_path(tournament)

    assert_redirected_to draw_tournament_path(tournament)
    assert_predicate tournament.reload, :draw_scheduling?
    assert_not tournament.late_registration_allowed_for?(@organizer)
  end

  test "set draw is blocked before registration closes" do
    tournament = Tournament.create!(
      name: "Open Draw Open",
      organizer: @organizer,
      status: :registration_open,
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now,
      start_date: 2.days.from_now.to_date,
      end_date: 3.days.from_now.to_date
    )

    patch set_draw_tournament_path(tournament)

    assert_redirected_to tournament_path(tournament)
    assert_not_predicate tournament.reload, :draw_scheduling?
  end
end
