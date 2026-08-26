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
end
