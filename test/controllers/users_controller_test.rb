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
    assert_includes response.body, "super admin will verify"
    assert_includes response.body, 'value="organizer"'
    assert_includes response.body, "Profile photo URL"
  end

  test "new user page explains academy owner account role" do
    get new_user_path(account_type: "academy_owner", return_to: new_academy_path)

    assert_response :success
    assert_includes response.body, "ACADEMY OWNER ACCOUNT"
    assert_includes response.body, "Create academy owner account"
    assert_includes response.body, "submit your academy"
    assert_includes response.body, 'value="academy_owner"'
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

  test "creates pending organizer account and sends it to verification" do
    assert_difference("User.count", 1) do
      post users_path, params: {
        account_type: "organizer",
        return_to: new_tournament_path,
        user: {
          name: "New Organizer",
          email: "new-organizer@example.com",
          profile_photo_url: "https://example.com/organizer.jpg",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    user = User.order(:created_at).last
    assert_predicate user, :organizer?
    assert_predicate user, :organizer_pending?
    assert_equal "https://example.com/organizer.jpg", user.profile_photo_url
    assert_equal user.id, session[:user_id]
    assert_redirected_to organizers_path
    assert_equal "Organizer account created and sent to super admin for verification.", flash[:notice]
  end

  test "creates academy owner account and returns to academy registration" do
    assert_difference("User.count", 1) do
      post users_path, params: {
        account_type: "academy_owner",
        return_to: new_academy_path,
        user: {
          name: "New Academy Owner",
          email: "new-academy-owner@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    user = User.order(:created_at).last
    assert_predicate user, :academy_owner?
    assert_equal user.id, session[:user_id]
    assert_redirected_to new_academy_path
  end
end
