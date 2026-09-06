require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  test "requesting a reset for a known email enqueues an email without revealing whether it exists" do
    user = User.create!(name: "Demo Parent", email: "reset-parent@example.test", password: "password123", role: :parent)

    assert_enqueued_email_with PasswordMailer, :reset_instructions, params: { user: user } do
      post password_reset_path, params: { email: "reset-parent@example.test" }
    end

    assert_redirected_to login_path
    assert_equal "If that email is registered, we've sent instructions to reset the password.", flash[:notice]
  end

  test "requesting a reset for an unknown email shows the same message and sends nothing" do
    assert_no_enqueued_emails do
      post password_reset_path, params: { email: "nobody@example.test" }
    end

    assert_redirected_to login_path
    assert_equal "If that email is registered, we've sent instructions to reset the password.", flash[:notice]
  end

  test "a valid token lets the user set a new password and sign in with it" do
    user = User.create!(name: "Demo Parent", email: "reset-flow-parent@example.test", password: "password123", role: :parent)
    token = user.generate_token_for(:password_reset)

    get edit_password_reset_path(token: token)
    assert_response :success

    patch password_reset_path, params: { token: token, user: { password: "newpassword456", password_confirmation: "newpassword456" } }

    assert_redirected_to login_path
    assert_equal "Password updated. Please sign in.", flash[:notice]

    post login_path, params: { email: "reset-flow-parent@example.test", password: "newpassword456" }
    assert_redirected_to tournaments_path
  end

  test "an invalid or expired token is rejected" do
    get edit_password_reset_path(token: "not-a-real-token")

    assert_redirected_to new_password_reset_path
    assert_equal "That password reset link is invalid or has expired.", flash[:alert]
  end

  test "a token becomes invalid once the password has already been changed" do
    user = User.create!(name: "Demo Parent", email: "reused-token-parent@example.test", password: "password123", role: :parent)
    token = user.generate_token_for(:password_reset)

    patch password_reset_path, params: { token: token, user: { password: "firstnewpassword1", password_confirmation: "firstnewpassword1" } }
    assert_redirected_to login_path

    get edit_password_reset_path(token: token)

    assert_redirected_to new_password_reset_path
    assert_equal "That password reset link is invalid or has expired.", flash[:alert]
  end

  test "mismatched password confirmation shows a validation error" do
    user = User.create!(name: "Demo Parent", email: "mismatch-parent@example.test", password: "password123", role: :parent)
    token = user.generate_token_for(:password_reset)

    patch password_reset_path, params: { token: token, user: { password: "newpassword456", password_confirmation: "different789" } }

    assert_response :unprocessable_entity
    assert_includes response.body, "Password confirmation doesn&#39;t match"
  end

  test "already signed in users are redirected away from the reset flow" do
    user = User.create!(name: "Demo Parent", email: "signed-in-reset-parent@example.test", password: "password123", role: :parent)
    sign_in_as user

    get new_password_reset_path

    assert_redirected_to tournaments_path
  end
end
