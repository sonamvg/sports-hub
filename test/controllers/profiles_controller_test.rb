require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "signed out users are redirected to sign in" do
    get profile_path

    assert_redirected_to login_path(return_to: profile_path)
  end

  test "shows the signed-in user's own account details" do
    user = User.create!(name: "Demo Athlete", email: "profile-athlete@example.test", phone: "9876543210", password: "password123", role: :athlete)
    user.athletes.create!(first_name: "Demo", last_name: "Athlete", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as user

    get profile_path

    assert_response :success
    assert_includes response.body, "Demo Athlete"
    assert_includes response.body, "profile-athlete@example.test"
    assert_includes response.body, "9876543210"
  end

  test "updates the account's name and phone" do
    user = User.create!(name: "Old Name", email: "profile-edit-parent@example.test", phone: "9876543210", password: "password123", role: :parent)
    sign_in_as user

    patch profile_path, params: { user: { name: "New Name", phone: "9111111111" } }

    assert_redirected_to profile_path
    assert_equal "Profile updated.", flash[:notice]
    user.reload
    assert_equal "New Name", user.name
    assert_equal "9111111111", user.phone
  end

  test "editing the profile cannot change the email" do
    user = User.create!(name: "Demo Parent", email: "profile-edit-no-email-change@example.test", password: "password123", role: :parent)
    sign_in_as user

    patch profile_path, params: { user: { name: "Demo Parent", email: "someone-else@example.test" } }

    assert_redirected_to profile_path
    assert_equal "profile-edit-no-email-change@example.test", user.reload.email
  end

  test "rejects an invalid name on profile edit" do
    user = User.create!(name: "Demo Parent", email: "profile-edit-invalid-name@example.test", password: "password123", role: :parent)
    sign_in_as user

    patch profile_path, params: { user: { name: "Invalid123" } }

    assert_response :unprocessable_entity
    assert_includes response.body, "can only contain letters, spaces, hyphens, and apostrophes"
    assert_equal "Demo Parent", user.reload.name
  end

  test "sidebar links the user's name to their profile" do
    user = User.create!(name: "Demo Organizer", email: "profile-nav-organizer@example.test", password: "password123", role: :organizer, organizer_status: :verified)
    sign_in_as user

    get tournaments_path

    assert_response :success
    assert_includes response.body, "class=\"status-pill\" href=\"#{profile_path}\""
  end

  test "sidebar shows the account's role next to the name" do
    academy_owner = User.create!(name: "Demo Owner", email: "profile-role-academy-owner@example.test", password: "password123", role: :academy_owner)
    sign_in_as academy_owner

    get tournaments_path

    assert_response :success
    assert_includes response.body, "<span class=\"small-label\">Academy Owner</span>"

    delete logout_path
    super_admin = User.create!(name: "Demo Admin", email: "profile-role-super-admin@example.test", password: "password123", role: :super_admin)
    sign_in_as super_admin

    get tournaments_path

    assert_response :success
    assert_includes response.body, "<span class=\"small-label\">Super Admin</span>"
  end

  test "updates the password when the current password is correct" do
    user = User.create!(name: "Demo Parent", email: "profile-password-parent@example.test", password: "password123", role: :parent)
    sign_in_as user

    patch update_password_profile_path, params: {
      user: { current_password: "password123", password: "newpassword456", password_confirmation: "newpassword456" }
    }

    assert_redirected_to profile_path
    assert_equal "Password updated.", flash[:notice]

    post login_path, params: { email: "profile-password-parent@example.test", password: "newpassword456" }
    assert_redirected_to tournaments_path
  end

  test "rejects the change when the current password is wrong" do
    user = User.create!(name: "Demo Parent", email: "profile-wrong-current-parent@example.test", password: "password123", role: :parent)
    sign_in_as user

    patch update_password_profile_path, params: {
      user: { current_password: "not-the-password", password: "newpassword456", password_confirmation: "newpassword456" }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Current password is incorrect"
    assert user.reload.authenticate("password123")
  end

  test "rejects the change when the current password is blank" do
    user = User.create!(name: "Demo Parent", email: "profile-blank-current-parent@example.test", password: "password123", role: :parent)
    sign_in_as user

    patch update_password_profile_path, params: {
      user: { current_password: "", password: "newpassword456", password_confirmation: "newpassword456" }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Current password must be entered"
  end

  test "rejects a mismatched password confirmation" do
    user = User.create!(name: "Demo Parent", email: "profile-mismatch-parent@example.test", password: "password123", role: :parent)
    sign_in_as user

    patch update_password_profile_path, params: {
      user: { current_password: "password123", password: "newpassword456", password_confirmation: "different789" }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Password confirmation doesn&#39;t match"
    assert user.reload.authenticate("password123")
  end

  test "rejects a new password that is too short" do
    user = User.create!(name: "Demo Parent", email: "profile-short-parent@example.test", password: "password123", role: :parent)
    sign_in_as user

    patch update_password_profile_path, params: {
      user: { current_password: "password123", password: "short1", password_confirmation: "short1" }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "too short"
    assert user.reload.authenticate("password123")
  end

  test "works the same for an academy owner account" do
    user = User.create!(name: "Demo Academy Owner", email: "profile-academy-owner@example.test", password: "password123", role: :academy_owner)
    sign_in_as user

    patch update_password_profile_path, params: {
      user: { current_password: "password123", password: "newpassword456", password_confirmation: "newpassword456" }
    }

    assert_redirected_to profile_path
    assert user.reload.authenticate("newpassword456")
  end

  test "athlete deleting their account removes the account and their athlete profile" do
    user = User.create!(name: "Demo Athlete", email: "delete-athlete@example.test", password: "password123", role: :athlete)
    athlete = user.athletes.create!(first_name: "Demo", last_name: "Athlete", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as user

    assert_difference(["User.count", "Athlete.count"], -1) do
      delete profile_path
    end

    assert_redirected_to root_path
    assert_equal "Your account has been deleted.", flash[:notice]
    assert_not User.exists?(user.id)
    assert_not Athlete.exists?(athlete.id)
  end

  test "academy owner deleting their account removes the academy but keeps its athletes, unlinked" do
    owner = User.create!(name: "Demo Owner", email: "delete-academy-owner@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Delete Test Academy", city: "Pune", status: :approved, owner: owner)
    roster_athlete_user = User.create!(name: "Roster Athlete", email: "delete-academy-roster@example.test", password: "password123", role: :athlete)
    roster_athlete = roster_athlete_user.athletes.create!(academy: academy, first_name: "Roster", last_name: "Athlete", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as owner

    assert_difference("Academy.count", -1) do
      assert_no_difference("Athlete.count") do
        delete profile_path
      end
    end

    assert_redirected_to root_path
    assert_not User.exists?(owner.id)
    assert_not Academy.exists?(academy.id)
    assert Athlete.exists?(roster_athlete.id)
    assert_nil roster_athlete.reload.academy_id
  end

  test "organizer deleting their account with only open tournaments removes the account entirely" do
    organizer = User.create!(name: "Demo Organizer", email: "delete-open-organizer@example.test", password: "password123", role: :organizer, organizer_status: :verified)
    open_tournament = Tournament.create!(name: "Open Event", organizer: organizer, status: :registration_open, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    sign_in_as organizer

    assert_difference("User.count", -1) do
      assert_difference("Tournament.count", -1) do
        delete profile_path
      end
    end

    assert_redirected_to root_path
    assert_equal "Your account has been deleted.", flash[:notice]
    assert_not User.exists?(organizer.id)
    assert_not Tournament.exists?(open_tournament.id)
  end

  test "organizer deleting their account with a closed tournament is deactivated instead, and the closed tournament is preserved" do
    organizer = User.create!(name: "Demo Organizer", email: "delete-closed-organizer@example.test", password: "password123", role: :organizer, organizer_status: :verified)
    open_tournament = Tournament.create!(name: "Open Event", organizer: organizer, status: :registration_open, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    closed_tournament = Tournament.create!(name: "Completed Event", organizer: organizer, status: :completed, start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 6))
    sign_in_as organizer

    assert_no_difference("User.count") do
      assert_difference("Tournament.count", -1) do
        delete profile_path
      end
    end

    assert_redirected_to root_path
    assert_equal "Your account has been deactivated. Your closed tournaments have been preserved.", flash[:notice]
    assert_not Tournament.exists?(open_tournament.id)
    assert Tournament.exists?(closed_tournament.id)
    assert_equal "Completed Event", closed_tournament.reload.name
    assert_equal organizer.id, closed_tournament.organizer_id

    organizer.reload
    assert_predicate organizer, :deactivated?
    assert_no_enqueued_emails do
      post login_path, params: { email: "delete-closed-organizer@example.test", password: "password123" }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Invalid email or password."
  end

  test "super admin cannot delete their account from the profile page" do
    super_admin = User.create!(name: "Demo Admin", email: "delete-super-admin@example.test", password: "password123", role: :super_admin)
    sign_in_as super_admin

    assert_no_difference("User.count") do
      delete profile_path
    end

    assert_redirected_to profile_path
    assert_equal "Super admin accounts can't be deleted from here.", flash[:alert]
    assert User.exists?(super_admin.id)
  end

  test "delete account option is not shown for a super admin" do
    super_admin = User.create!(name: "Demo Admin", email: "no-delete-button-admin@example.test", password: "password123", role: :super_admin)
    sign_in_as super_admin

    get profile_path

    assert_response :success
    assert_not_includes response.body, "Delete account"
  end
end
