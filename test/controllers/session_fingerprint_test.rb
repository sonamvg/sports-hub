require "test_helper"

class SessionFingerprintTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Demo Organizer", email: "session-fingerprint@example.test", password: "password123", role: :organizer, organizer_status: :verified)
  end

  test "stays signed in across requests from the same browser" do
    post login_path, params: { email: @user.email, password: "password123" }, headers: { "User-Agent" => "TestBrowser/1.0" }

    get tournaments_path, headers: { "User-Agent" => "TestBrowser/1.0" }

    assert_response :success
    assert_includes response.body, "Sign out"
  end

  test "signs out when the session cookie is used from a different browser" do
    post login_path, params: { email: @user.email, password: "password123" }, headers: { "User-Agent" => "TestBrowser/1.0" }
    get tournaments_path, headers: { "User-Agent" => "TestBrowser/1.0" }
    assert_response :success

    get tournaments_path, headers: { "User-Agent" => "SomeOtherBrowser/9.0" }

    assert_redirected_to login_path
    assert_equal "Your session could not be verified for this browser. Please sign in again.", flash[:alert]

    follow_redirect!
    assert_includes response.body, "Sign in"
    assert_not_includes response.body, "Sign out"
  end
end
