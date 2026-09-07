require "test_helper"

class SessionTimeoutTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Demo Organizer", email: "session-timeout@example.test", password: "password123", role: :organizer, organizer_status: :verified)
    sign_in_as @user
  end

  test "stays signed in when requests keep arriving within the idle window" do
    travel ApplicationController::SESSION_TIMEOUT - 1.minute do
      get tournaments_path
    end

    assert_response :success
    assert_includes response.body, "Sign out"
  end

  test "signs out and redirects to login after the idle window elapses" do
    get tournaments_path
    assert_response :success

    travel ApplicationController::SESSION_TIMEOUT + 1.minute do
      get tournaments_path
    end

    assert_redirected_to login_path
    assert_equal "You've been signed out due to inactivity. Please sign in again.", flash[:alert]

    follow_redirect!
    assert_includes response.body, "Sign in"
    assert_not_includes response.body, "Sign out"
  end

  test "activity slides the idle window forward instead of using a fixed session lifetime" do
    travel(ApplicationController::SESSION_TIMEOUT - 1.minute) { get tournaments_path }
    assert_response :success

    travel(ApplicationController::SESSION_TIMEOUT - 1.minute) { get tournaments_path }
    assert_response :success
    assert_includes response.body, "Sign out"
  end

  test "session timeout data attribute is rendered for a signed-in user and omitted for a guest" do
    get tournaments_path
    assert_includes response.body, "data-session-timeout-seconds=\"#{ApplicationController::SESSION_TIMEOUT.to_i}\""

    delete logout_path
    get tournaments_path
    assert_not_includes response.body, "data-session-timeout-seconds"
  end
end
