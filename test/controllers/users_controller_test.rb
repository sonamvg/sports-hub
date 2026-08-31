require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "new user page explains athlete account role" do
    get new_user_path

    assert_response :success
    assert_includes response.body, "Join as athlete"
    assert_includes response.body, "Create athlete account"
    assert_includes response.body, "No approval is required"
    assert_includes response.body, "Phone number"
  end

  test "new user page explains organizer account role" do
    get new_user_path(account_type: "organizer", return_to: new_tournament_path)

    assert_response :success
    assert_includes response.body, "ORGANIZER ACCOUNT"
    assert_includes response.body, "Create organizer account"
    assert_includes response.body, "super admin will verify"
    assert_includes response.body, 'value="organizer"'
    assert_includes response.body, "Mobile number"
    assert_includes response.body, "Designation"
    assert_includes response.body, "Academy affiliation"
    assert_includes response.body, "Identity verification document"
    assert_includes response.body, "Profile photo URL"
  end

  test "new user page explains academy owner account role" do
    get new_user_path(account_type: "academy_owner", return_to: new_academy_path)

    assert_response :success
    assert_includes response.body, "ACADEMY ACCOUNT"
    assert_includes response.body, "Register academy"
    assert_includes response.body, "submit your academy"
    assert_includes response.body, 'value="academy_owner"'
    assert_not_includes response.body, "Create academy owner account"
  end

  test "signed in user cannot open another account registration page" do
    user = User.create!(name: "Existing User", email: "existing-user@example.com", password: "password123", role: :super_admin)
    sign_in_as user

    get new_user_path(account_type: "organizer", return_to: new_tournament_path)

    assert_redirected_to tournaments_path
    assert_equal "You are already signed in.", flash[:alert]
  end

  test "signed in user cannot create another account by posting directly" do
    user = User.create!(name: "Existing Direct User", email: "existing-direct-user@example.com", password: "password123", role: :super_admin)
    sign_in_as user

    assert_no_difference("User.count") do
      post users_path, params: {
        user: {
          name: "Second Account",
          email: "second-account@example.com",
          phone: "9876543210",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to tournaments_path
    assert_equal "You are already signed in.", flash[:alert]
  end

  test "creates athlete account and sends user to profile completion" do
    assert_difference("User.count", 1) do
      post users_path, params: {
        user: {
          name: "New Athlete",
          email: "new-athlete@example.com",
          phone: "9876543210",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    user = User.order(:created_at).last
    assert_predicate user, :athlete?
    assert_equal "9876543210", user.phone
    assert_equal user.id, session[:user_id]
    assert_redirected_to new_athlete_path(profile_setup: true)
    assert_equal "Athlete account created. Complete your profile to continue.", flash[:notice]
  end

  test "creates pending organizer account and sends it to verification" do
    assert_difference("User.count", 1) do
      post users_path, params: {
        account_type: "organizer",
        return_to: new_tournament_path,
        user: {
          name: "New Organizer",
          email: "new-organizer@example.com",
          phone: "9876543210",
          organizer_designation: "Tournament Director",
          profile_photo_url: "https://example.com/organizer.jpg",
          identity_document: identity_document_upload,
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    user = User.order(:created_at).last
    assert_predicate user, :organizer?
    assert_predicate user, :organizer_pending?
    assert_equal "9876543210", user.phone
    assert_equal "Tournament Director", user.organizer_designation
    assert_equal "https://example.com/organizer.jpg", user.profile_photo_url
    assert_predicate user.identity_document, :attached?
    assert_equal user.id, session[:user_id]
    assert_redirected_to organizers_path
    assert_equal "Organizer account created and sent to super admin for verification.", flash[:notice]
  end

  test "organizer signup requires mobile designation and identity document" do
    assert_no_difference("User.count") do
      post users_path, params: {
        account_type: "organizer",
        user: {
          name: "New Organizer",
          email: "missing-verification@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Phone can&#39;t be blank"
    assert_includes response.body, "Organizer designation can&#39;t be blank"
    assert_includes response.body, "Identity document must be uploaded"
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
