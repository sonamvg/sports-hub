require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "signs in with valid credentials" do
    user = User.create!(name: "Demo Super Admin", email: "admin@example.com", password: "password123", role: :super_admin)

    post login_path, params: { email: "ADMIN@example.com ", password: "password123" }

    assert_redirected_to tournaments_path
    assert_equal user.id, session[:user_id]
    assert_equal "Signed in as Demo Super Admin.", flash[:notice]
  end

  test "rejects invalid credentials" do
    User.create!(name: "Demo Super Admin", email: "admin@example.com", password: "password123", role: :super_admin)

    post login_path, params: { email: "admin@example.com", password: "wrong" }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_includes response.body, "Invalid email or password."
    assert_includes response.body, "Join as athlete"
  end

  test "signs out" do
    user = User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :parent)
    sign_in_as user

    delete logout_path

    assert_redirected_to root_path
    assert_nil session[:user_id]
  end
end
