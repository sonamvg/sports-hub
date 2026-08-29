require "test_helper"

class AthletesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @parent = User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :parent)
    sign_in_as @parent
  end

  test "creates athlete profile for current user" do
    assert_difference("Athlete.count", 1) do
      post athletes_path, params: {
        athlete: {
          first_name: "Aarohi",
          last_name: "Shah",
          date_of_birth: Date.new(2014, 5, 12),
          gender: "female",
          belt: "red",
          weight: 39.5,
          blood_group: "O+",
          contact_number: "9876543210",
          emergency_contact_name: "Demo Parent",
          emergency_contact_phone: "9876500000",
          address: "Line 1, Sports Nagar",
          city: "Pune",
          state: "Maharashtra",
          government_id_document_type: "Aadhaar",
          profile_photo: tournament_image_upload,
          identity_document: identity_document_upload
        }
      }
    end

    athlete = Athlete.order(:created_at).last
    assert_equal @parent, athlete.user
    assert_equal "O+", athlete.blood_group
    assert_equal "9876543210", athlete.contact_number
    assert_equal "Line 1, Sports Nagar", athlete.address
    assert_equal "Aadhaar", athlete.government_id_document_type
    assert_predicate athlete.profile_photo, :attached?
    assert_predicate athlete.identity_document, :attached?
    assert_redirected_to athlete_path(athlete)
    assert_equal "Athlete profile created.", flash[:notice]
  end

  test "athlete account without profile is redirected to profile setup" do
    athlete_user = User.create!(name: "New Athlete", email: "new-athlete-profile@example.test", phone: "9876543210", password: "password123", role: :athlete)
    sign_in_as athlete_user

    get tournaments_path

    assert_redirected_to new_athlete_path(profile_setup: true)
    assert_equal "Complete your athlete profile to continue.", flash[:alert]
  end

  test "athlete account with profile is redirected from athletes index to own profile" do
    athlete_user = User.create!(name: "Athlete User", email: "athlete-index@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as athlete_user

    get athletes_path(q: "aarohi", belt: "red")

    assert_redirected_to athlete_path(athlete)
  end

  test "athlete profile shows upcoming tournament application and weight check statuses" do
    athlete_user = User.create!(name: "Athlete User", email: "athlete-status@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", association_id: "TKD-123", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    organizer = User.create!(name: "Organizer", email: "athlete-status-organizer@example.test", password: "password123", role: :organizer)
    upcoming = Tournament.create!(name: "Future Open", organizer: organizer, start_date: 20.days.from_now.to_date, end_date: 21.days.from_now.to_date)
    pending_category = upcoming.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    approved_category = upcoming.tournament_categories.create!(event_type: "poomsae", gender: "female", age_min: 12, age_max: 14)
    declined_category = upcoming.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 37, weight_max: 41)
    verified_category = upcoming.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 33)
    disqualified_category = upcoming.tournament_categories.create!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    upcoming.registrations.create!(athlete: athlete, tournament_category: pending_category, status: :pending, payment_receipt: payment_receipt_upload)
    upcoming.registrations.create!(athlete: athlete, tournament_category: approved_category, status: :approved, payment_receipt: payment_receipt_upload)
    upcoming.registrations.create!(athlete: athlete, tournament_category: declined_category, status: :rejected, payment_receipt: payment_receipt_upload)
    verified_registration = upcoming.registrations.create!(athlete: athlete, tournament_category: verified_category, status: :approved, payment_receipt: payment_receipt_upload)
    verified_registration.registration_weight_checks.create!(checked_by: organizer, weight: 32.8)
    opponent_user = User.create!(name: "Opponent User", email: "athlete-status-opponent@example.test", password: "password123", role: :athlete)
    opponent = opponent_user.athletes.create!(first_name: "Meera", last_name: "Rao", date_of_birth: Date.new(2014, 5, 12), gender: "female", external_academy_name: "Opponent Dojang")
    opponent_registration = upcoming.registrations.create!(athlete: opponent, tournament_category: verified_category, status: :weight_verified, payment_receipt: payment_receipt_upload)
    draw = upcoming.tournament_draws.create!(tournament_category: verified_category, generated_by: organizer, bracket_size: 2, round_count: 1, entry_count: 2, generated_at: Time.current)
    draw.tournament_draw_matches.create!(
      round_number: 1,
      position: 1,
      red_registration: verified_registration,
      blue_registration: opponent_registration,
      red_round_1_points: 9,
      blue_round_1_points: 4,
      red_round_2_points: 7,
      blue_round_2_points: 5,
      red_round_3_points: 6,
      blue_round_3_points: 3,
      red_head_guard_color: "red",
      blue_head_guard_color: "blue",
      winner_registration: verified_registration,
      completed_by: organizer,
      completed_at: Time.current
    )
    disqualified_registration = upcoming.registrations.create!(athlete: athlete, tournament_category: disqualified_category, status: :approved, payment_receipt: payment_receipt_upload)
    disqualified_registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.5)
    disqualified_registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.1)
    disqualified_registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.0)
    past = Tournament.create!(name: "Past Open", organizer: organizer, start_date: 20.days.ago.to_date, end_date: 19.days.ago.to_date)
    past_category = past.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 37)
    past.registrations.create!(athlete: athlete, tournament_category: past_category, status: :approved, payment_receipt: payment_receipt_upload)
    sign_in_as athlete_user

    get athlete_path(athlete)

    assert_response :success
    assert_includes response.body, "Upcoming tournaments"
    assert_includes response.body, "Future Open"
    assert_includes response.body, "Application submitted"
    assert_includes response.body, "Waiting for organiser review."
    assert_includes response.body, "Registered"
    assert_includes response.body, "Declined"
    assert_includes response.body, "Weight verified"
    assert_includes response.body, "Attempt 1: 32.8 kg passed"
    assert_includes response.body, "Gold medal"
    assert_includes response.body, "22 - 12"
    assert_includes response.body, "Red"
    assert_includes response.body, "Disqualified"
    assert_includes response.body, "Attempt 3: 38 kg failed"
    assert_includes response.body, "Previous competitions"
    assert_includes response.body, "Past Open"
    assert_not_includes response.body, "Association ID"
    assert_not_includes response.body, "TKD-123"
  end

  test "athlete account with profile cannot add another athlete" do
    athlete_user = User.create!(name: "Athlete User", email: "athlete-extra@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as athlete_user

    get new_athlete_path

    assert_redirected_to athlete_path(athlete)
    assert_equal "Athlete accounts can manage only their own profile.", flash[:alert]

    assert_no_difference("Athlete.count") do
      post athletes_path, params: {
        athlete: {
          first_name: "Second",
          last_name: "Athlete",
          date_of_birth: Date.new(2015, 5, 12),
          gender: "female"
        }
      }
    end

    assert_redirected_to athlete_path(athlete)
  end

  test "athlete selecting registered academy creates membership request instead of direct link" do
    owner = User.create!(name: "Academy Owner", email: "request-owner@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "academy-request-athlete@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as athlete_user

    assert_difference("AcademyMembershipRequest.pending.count", 1) do
      patch athlete_path(athlete), params: {
        athlete: {
          first_name: "Aarohi",
          last_name: "Shah",
          date_of_birth: Date.new(2014, 5, 12),
          gender: "female",
          academy_id: academy.id
        }
      }
    end

    assert_redirected_to athlete_path(athlete)
    assert_equal "Academy join request sent to the academy owner.", flash[:notice]
    assert_nil athlete.reload.academy_id
    request = AcademyMembershipRequest.pending.order(:created_at).last
    assert_equal academy, request.academy
    assert_equal athlete, request.athlete
    assert_equal athlete_user, request.requested_by
  end

  test "athlete edit form shows academy dropdown with other and hides association id" do
    owner = User.create!(name: "Academy Owner", email: "athlete-form-owner@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Registered Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "athlete-form-self@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", association_id: "TKD-123")
    sign_in_as athlete_user

    get edit_athlete_path(athlete)

    assert_response :success
    assert_includes response.body, "Academy"
    assert_includes response.body, "Registered Academy"
    assert_includes response.body, "Other"
    assert_includes response.body, "data-academy-choice-select"
    assert_not_includes response.body, "Association ID"
    assert_not_includes response.body, "TKD-123"
  end

  test "athlete can save unregistered academy name without membership request" do
    athlete_user = User.create!(name: "Athlete User", email: "external-academy-athlete@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as athlete_user

    assert_no_difference("AcademyMembershipRequest.count") do
      patch athlete_path(athlete), params: {
        athlete: {
          first_name: "Aarohi",
          last_name: "Shah",
          date_of_birth: Date.new(2014, 5, 12),
          gender: "female",
          academy_id: "other",
          external_academy_name: "Independent Dojang"
        }
      }
    end

    assert_redirected_to athlete_path(athlete)
    assert_equal "Independent Dojang", athlete.reload.external_academy_name
    assert_nil athlete.academy_id
  end

  test "athlete registered academy request clears external academy text" do
    owner = User.create!(name: "Academy Owner", email: "clear-external-owner@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Linked Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "clear-external-athlete@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", external_academy_name: "Old External", association_id: "TKD-123")
    sign_in_as athlete_user

    assert_difference("AcademyMembershipRequest.pending.count", 1) do
      patch athlete_path(athlete), params: {
        athlete: {
          first_name: "Aarohi",
          last_name: "Shah",
          date_of_birth: Date.new(2014, 5, 12),
          gender: "female",
          academy_id: academy.id,
          external_academy_name: "Should Not Persist",
          association_id: "CHANGED"
        }
      }
    end

    assert_redirected_to athlete_path(athlete)
    assert_nil athlete.reload.external_academy_name
    assert_equal "TKD-123", athlete.association_id
  end

  test "returns to registration flow after creating athlete from registration page" do
    return_path = "/tournaments/42/registrations/new"

    post athletes_path, params: {
      return_to: return_path,
      athlete: {
        first_name: "Vihaan",
        last_name: "Mehta",
        date_of_birth: Date.new(2012, 3, 3),
        gender: "male"
      }
    }

    assert_redirected_to return_path
  end

  test "ignores unsafe return paths" do
    post athletes_path, params: {
      return_to: "//evil.example",
      athlete: {
        first_name: "Vihaan",
        last_name: "Mehta",
        date_of_birth: Date.new(2012, 3, 3),
        gender: "male"
      }
    }

    assert_redirected_to athlete_path(Athlete.order(:created_at).last)
  end

  test "normal user cannot view another user's athlete profile" do
    other_user = User.create!(name: "Other Parent", email: "other-parent@example.test", password: "password123", role: :parent)
    athlete = other_user.athletes.create!(
      first_name: "Anaya",
      last_name: "Iyer",
      date_of_birth: Date.new(2016, 9, 22),
      gender: "female"
    )

    get athlete_path(athlete)

    assert_response :not_found
  end

  test "academy owner can view athletes assigned to owned academy" do
    owner = User.create!(name: "Academy Owner", email: "academy-owner-athlete@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Owned Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "academy-athlete@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as owner

    get athlete_path(athlete)

    assert_response :success
    assert_includes response.body, "Aarohi Shah"
  end

  test "academy owner cannot edit athletes assigned to owned academy" do
    owner = User.create!(name: "Academy Owner", email: "academy-owner-no-edit@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Owned Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "academy-athlete-no-edit@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as owner

    get athlete_path(athlete)

    assert_response :success
    assert_not_includes response.body, edit_athlete_path(athlete)

    get edit_athlete_path(athlete)
    assert_response :not_found

    patch athlete_path(athlete), params: {
      athlete: {
        first_name: "Changed",
        last_name: "Shah",
        date_of_birth: Date.new(2014, 5, 12),
        gender: "female"
      }
    }
    assert_response :not_found
    assert_equal "Aarohi", athlete.reload.first_name
  end

  test "organizer cannot search athletes from athletes tab" do
    organizer = User.create!(name: "Organizer", email: "athlete-search-organizer@example.test", password: "password123", role: :organizer)
    sign_in_as organizer

    get athletes_path(q: "aarohi", age_min: 10, weight_min: 30, belt: "red")

    assert_response :success
    assert_includes response.body, "Athlete search is not available for organisers"
    assert_not_includes response.body, "Min age"
    assert_not_includes response.body, "Max weight"
    assert_not_includes response.body, "Any belt"
  end

  test "organizer can view profile of athlete registered for managed tournament" do
    organizer = User.create!(name: "Organizer", email: "registered-athlete-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "registered-athlete-user@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Managed Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :pending, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    get athlete_path(athlete)

    assert_response :success
    assert_includes response.body, "Aarohi Shah"
  end

  test "super admin can view another user's athlete profile" do
    other_user = User.create!(name: "Other Parent", email: "other-parent@example.test", password: "password123", role: :parent)
    athlete = other_user.athletes.create!(
      first_name: "Anaya",
      last_name: "Iyer",
      date_of_birth: Date.new(2016, 9, 22),
      gender: "female"
    )
    super_admin = User.create!(name: "Super Admin", email: "admin@example.test", password: "password123", role: :super_admin)
    sign_in_as super_admin

    get athlete_path(athlete)

    assert_response :success
    assert_includes response.body, "Anaya Iyer"
  end

  test "super admin can see and delete all athletes" do
    first_user = User.create!(name: "First Parent", email: "first-parent@example.test", password: "password123", role: :parent)
    second_user = User.create!(name: "Second Parent", email: "second-parent@example.test", password: "password123", role: :parent)
    first_athlete = first_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    second_athlete = second_user.athletes.create!(first_name: "Vihaan", last_name: "Mehta", date_of_birth: Date.new(2013, 7, 2), gender: "male")
    super_admin = User.create!(name: "Super Admin", email: "all-athletes-admin@example.test", password: "password123", role: :super_admin)
    sign_in_as super_admin

    get athletes_path

    assert_response :success
    assert_includes response.body, "All athletes"
    assert_includes response.body, first_athlete.full_name
    assert_includes response.body, second_athlete.full_name
    assert_includes response.body, "Delete"

    get athlete_path(first_athlete)
    assert_response :success
    assert_includes response.body, "Delete athlete"

    assert_difference("Athlete.count", -1) do
      delete athlete_path(first_athlete)
    end

    assert_redirected_to athletes_path
    assert_equal "Athlete profile removed.", flash[:notice]
    assert_not Athlete.exists?(first_athlete.id)
    assert Athlete.exists?(second_athlete.id)
  end

  test "index filters athletes by search age weight and belt" do
    matching = @parent.athletes.create!(
      first_name: "Aarohi",
      last_name: "Shah",
      association_id: "TKD-22",
      date_of_birth: 12.years.ago.to_date,
      gender: "female",
      belt: "red",
      weight: 39.5
    )
    @parent.athletes.create!(
      first_name: "Vihaan",
      last_name: "Mehta",
      date_of_birth: 8.years.ago.to_date,
      gender: "male",
      belt: "blue",
      weight: 28
    )

    get athletes_path(q: "aarohi", age_min: 10, age_max: 14, weight_min: 35, weight_max: 45, belt: "red")

    assert_response :success
    assert_includes response.body, matching.full_name
    assert_not_includes response.body, "Vihaan Mehta"
    assert_includes response.body, "Min age"
    assert_includes response.body, "Max weight"
  end

  test "index paginates athletes" do
    13.times do |index|
      @parent.athletes.create!(
        first_name: "Athlete#{index}",
        last_name: "Page",
        date_of_birth: 12.years.ago.to_date,
        gender: "female"
      )
    end

    get athletes_path

    assert_response :success
    assert_includes response.body, "Page 1 of 2"
    assert_includes response.body, "Next"
  end
end
