require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
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
end
