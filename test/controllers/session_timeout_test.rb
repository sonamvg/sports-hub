require "test_helper"

class SessionTimeoutTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Demo Parent", email: "session-timeout@example.test", password: "password123", role: :parent)
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

  test "an organizer stays signed in past the default idle window, inside the extended one" do
    organizer = User.create!(name: "Demo Organizer", email: "session-timeout-organizer@example.test", password: "password123", role: :organizer, organizer_status: :verified)
    sign_in_as organizer

    get tournaments_path
    assert_includes response.body, "data-session-timeout-seconds=\"#{ApplicationController::EXTENDED_SESSION_TIMEOUT.to_i}\""

    travel(ApplicationController::SESSION_TIMEOUT + 1.minute) { get tournaments_path }

    assert_response :success
    assert_includes response.body, "Sign out"
  end

  test "an organizer is signed out once the extended idle window itself elapses" do
    organizer = User.create!(name: "Demo Organizer", email: "session-timeout-organizer-2@example.test", password: "password123", role: :organizer, organizer_status: :verified)
    sign_in_as organizer

    get tournaments_path
    assert_response :success

    travel(ApplicationController::EXTENDED_SESSION_TIMEOUT + 1.minute) { get tournaments_path }

    assert_redirected_to login_path
  end

  test "a pending, unverified organizer still gets the extended idle window by role, not by verification status" do
    pending_organizer = User.create!(name: "Pending Organizer", email: "session-timeout-pending-organizer@example.test", password: "password123", role: :organizer)
    sign_in_as pending_organizer

    get tournaments_path
    assert_includes response.body, "data-session-timeout-seconds=\"#{ApplicationController::EXTENDED_SESSION_TIMEOUT.to_i}\""
  end

  test "a signed-in keepalive ping refreshes the idle window without a full page visit" do
    travel ApplicationController::SESSION_TIMEOUT - 1.minute do
      post session_keepalive_path, xhr: true
    end
    assert_response :no_content

    travel ApplicationController::SESSION_TIMEOUT - 1.minute do
      get tournaments_path
    end
    assert_response :success
    assert_includes response.body, "Sign out"
  end

  test "keepalive does nothing for a signed-out visitor" do
    delete logout_path

    post session_keepalive_path, xhr: true

    assert_response :unauthorized
  end
end
