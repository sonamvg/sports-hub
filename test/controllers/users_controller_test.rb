require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "new user page explains athlete account role" do
    get new_user_path

    assert_response :success
    assert_includes response.body, "Join as athlete"
    assert_includes response.body, "Create athlete account"
    assert_includes response.body, "general athlete or parent account"
  end

  test "new user page explains organizer account role" do
    get new_user_path(account_type: "organizer", return_to: new_tournament_path)

    assert_response :success
    assert_includes response.body, "ORGANIZER ACCOUNT"
    assert_includes response.body, "Create organizer account"
    assert_includes response.body, "publish tournaments"
    assert_includes response.body, 'value="organizer"'
  end

  test "creates general user account and signs in" do
    assert_difference("User.count", 1) do
      post users_path, params: {
        user: {
          name: "New Parent",
          email: "new-parent@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    user = User.order(:created_at).last
    assert_predicate user, :parent?
    assert_equal user.id, session[:user_id]
    assert_redirected_to tournaments_path
  end

  test "creates organizer account and returns to tournament creation" do
    assert_difference("User.count", 1) do
      post users_path, params: {
        account_type: "organizer",
        return_to: new_tournament_path,
        user: {
          name: "New Organizer",
          email: "new-organizer@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    user = User.order(:created_at).last
    assert_predicate user, :organizer?
    assert_equal user.id, session[:user_id]
    assert_redirected_to new_tournament_path
  end
end
