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
          external_academy_name: "Independent Dojang"
        }
      }
    end

    assert_redirected_to athlete_path(athlete)
    assert_equal "Independent Dojang", athlete.reload.external_academy_name
    assert_nil athlete.academy_id
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
