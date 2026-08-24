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
          city: "Pune"
        }
      }
    end

    athlete = Athlete.order(:created_at).last
    assert_equal @parent, athlete.user
    assert_redirected_to athlete_path(athlete)
    assert_equal "Athlete profile created.", flash[:notice]
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
end
