require "test_helper"

class AthleteFlowSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Security Organizer", email: "security-organizer@example.test", password: "password123", role: :organizer, organizer_status: :verified)
    @other_organizer = User.create!(name: "Other Organizer", email: "security-other-organizer@example.test", password: "password123", role: :organizer, organizer_status: :verified)
    @athlete_user = User.create!(name: "Security Athlete", email: "security-athlete@example.test", password: "password123", role: :athlete)
    @other_user = User.create!(name: "Other Athlete", email: "security-other-athlete@example.test", password: "password123", role: :athlete)
    @athlete = create_athlete(@athlete_user, first_name: "Aarohi", gender: "female", weight: 36.5)
    @other_athlete = create_athlete(@other_user, first_name: "Vihaan", gender: "male", weight: 39.5)
    @tournament = create_tournament(@organizer, name: "Security Open")
    @category = @tournament.tournament_categories.find_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
  end

  test "signed out users cannot open or submit tournament registrations" do
    assert_no_difference("Registration.count") do
      get new_tournament_registration_path(@tournament)
    end
    assert_redirected_to login_path(return_to: new_tournament_registration_path(@tournament))

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(@tournament), params: registration_params(@athlete, @category)
    end
    assert_redirected_to login_path(return_to: tournament_registrations_path(@tournament))
  end

  test "athlete id tampering cannot register another user's athlete" do
    sign_in_as @athlete_user

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(@tournament), params: registration_params(@other_athlete, @category)
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Athlete must be selected"
  end

  test "organizer cannot post registrations for an unrelated tournament" do
    sign_in_as @other_organizer

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(@tournament), params: registration_params(@athlete, @category)
    end

    assert_redirected_to tournament_path(@tournament)
    assert_equal "Registration is not open for this tournament.", flash[:alert]
  end

  test "category id tampering cannot register category from another tournament" do
    other_tournament = create_tournament(@organizer, name: "Other Security Open")
    other_category = other_tournament.tournament_categories.find_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    sign_in_as @athlete_user

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(@tournament), params: registration_params(@athlete, other_category)
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "included a category that is no longer available"
  end

  test "replayed duplicate registration request does not create duplicate rows" do
    sign_in_as @athlete_user

    assert_difference("Registration.count", 1) do
      post tournament_registrations_path(@tournament), params: registration_params(@athlete, @category)
      post tournament_registrations_path(@tournament), params: registration_params(@athlete, @category)
    end

    registration = Registration.find_by!(athlete: @athlete, tournament: @tournament, tournament_category: @category)
    assert_predicate registration, :pending?
  end

  test "client-side fee tampering is ignored and server snapshots tournament fee" do
    sign_in_as @athlete_user

    assert_difference("Registration.count", 1) do
      post tournament_registrations_path(@tournament), params: registration_params(@athlete, @category).deep_merge(
        registration: { fee_amount: "1", fee_currency: "USD" }
      )
    end

    registration = Registration.find_by!(athlete: @athlete, tournament: @tournament, tournament_category: @category)
    assert_equal BigDecimal("900"), registration.fee_amount
    assert_equal "INR", registration.fee_currency
  end

  test "future registration window cannot be bypassed by posting directly" do
    future_tournament = create_tournament(@organizer, name: "Future Security Open", opens_at: 1.day.from_now, closes_at: 3.days.from_now)
    future_category = future_tournament.tournament_categories.find_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    sign_in_as @athlete_user

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(future_tournament), params: registration_params(@athlete, future_category)
    end

    assert_redirected_to tournament_path(future_tournament)
    assert_equal "Registration is not open for this tournament.", flash[:alert]
  end

  test "closed registration window cannot be bypassed by posting directly" do
    closed_tournament = create_tournament(@organizer, name: "Closed Security Open", opens_at: 3.days.ago, closes_at: 1.day.ago)
    closed_category = closed_tournament.tournament_categories.find_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    sign_in_as @athlete_user

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(closed_tournament), params: registration_params(@athlete, closed_category)
    end

    assert_redirected_to tournament_path(closed_tournament)
    assert_equal "Registration is not open for this tournament.", flash[:alert]
  end

  test "unsafe payment receipt uploads are rejected through the registration controller" do
    sign_in_as @athlete_user

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(@tournament), params: registration_params(@athlete, @category, receipt: invalid_text_upload)
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Payment receipt must be a JPG, PNG, WebP, or PDF file"

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(@tournament), params: registration_params(@athlete, @category, receipt: oversized_upload)
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Payment receipt must be 5 MB or smaller"

    spoofed_upload = Rack::Test::UploadedFile.new(StringIO.new("#!/bin/bash\necho pwned\n"), "image/png", original_filename: "receipt.png")
    assert_no_difference("Registration.count") do
      post tournament_registrations_path(@tournament), params: registration_params(@athlete, @category, receipt: spoofed_upload)
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Payment receipt must be a JPG, PNG, WebP, or PDF file"
  end

  test "script-like athlete and academy fields are rejected or escaped" do
    sign_in_as @athlete_user

    patch athlete_path(@athlete), params: {
      athlete: {
        first_name: "<script>alert(1)</script>",
        last_name: "Shah",
        date_of_birth: Date.new(2014, 5, 12),
        gender: "female",
        contact_number: "9876543210",
        emergency_contact_name: "<script>alert(2)</script>",
        emergency_contact_phone: "9876543211",
        address: "<script>alert(3)</script>",
        city: "Pune"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "First name can only contain letters"
    assert_includes response.body, "Emergency contact name can only contain letters"

    @athlete.update!(address: "<script>alert(3)</script>")
    get athlete_path(@athlete)

    assert_response :success
    assert_not_includes response.body, "<script>alert(3)</script>"
    assert_includes response.body, "&lt;script&gt;alert(3)&lt;/script&gt;"

    assert_no_difference("Academy.count") do
      post academies_path, params: {
        academy: {
          name: "<script>alert(4)</script>",
          city: "Pune",
          terms_accepted: "1",
          data_sharing_consent: "1"
        }
      }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Name must contain letters"
  end

  test "sql-like search filters are treated as plain text" do
    super_admin = User.create!(name: "Security Super Admin", email: "security-super-admin@example.test", password: "password123", role: :super_admin)
    sign_in_as super_admin
    injection = "' OR 1=1 --"

    get athletes_path(q: injection, age_min: injection, weight_min: injection, belt: injection)
    assert_response :success

    get academies_path(q: injection)
    assert_response :success

    get tournaments_path(q: injection, country: injection, state: injection)
    assert_response :success
  end

  test "direct athlete profile edit delete and identity document access are scoped" do
    @other_athlete.identity_documents.attach(identity_image_upload)
    sign_in_as @athlete_user

    get athlete_path(@other_athlete)
    assert_response :not_found

    patch athlete_path(@other_athlete), params: {
      athlete: { first_name: "Changed", last_name: "Mehta", date_of_birth: Date.new(2014, 5, 12), gender: "male" }
    }
    assert_response :not_found
    assert_equal "Vihaan", @other_athlete.reload.first_name

    assert_no_difference("Athlete.count") do
      delete athlete_path(@other_athlete)
    end
    assert_response :not_found

    get identity_document_athlete_path(@other_athlete, attachment_id: @other_athlete.identity_documents.first.id)
    assert_response :not_found
  end

  test "protected payment and receipt details are not visible to signed out users" do
    registration = @tournament.registrations.create!(athlete: @athlete, tournament_category: @category, payment_receipt: payment_receipt_upload)

    get tournament_path(@tournament)
    assert_response :success
    assert_not_includes response.body, @tournament.payment_account_number
    assert_not_includes response.body, @tournament.payment_ifsc
    assert_not_includes response.body, @tournament.payment_upi_id
    assert_not_includes response.body, rails_blob_path(@tournament.payment_qr_image)

    get receipt_organizer_registration_path(registration)
    assert_redirected_to login_path(return_to: receipt_organizer_registration_path(registration))
  end

  test "registration form replay after logout does not create a registration" do
    sign_in_as @athlete_user
    get new_tournament_registration_path(@tournament)
    assert_response :success
    delete logout_path

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(@tournament), params: registration_params(@athlete, @category)
    end
    assert_redirected_to login_path(return_to: tournament_registrations_path(@tournament))
  end

  test "unsafe login return path is ignored" do
    post login_path, params: { email: @athlete_user.email, password: "password123", return_to: "//evil.example" }

    assert_redirected_to athlete_path(@athlete)
  end

  test "same email cannot be reused across athlete organizer and academy owner accounts" do
    assert_no_difference("User.count") do
      post users_path, params: {
        account_type: "organizer",
        user: {
          name: "Security Athlete",
          email: @athlete_user.email,
          phone: "9876543210",
          organizer_designation: "Coach",
          identity_document: identity_document_upload,
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Email has already been taken"

    assert_no_difference("User.count") do
      post users_path, params: {
        account_type: "academy_owner",
        user: {
          name: "Security Athlete",
          email: @athlete_user.email,
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Email has already been taken"
  end

  test "repeated failed login attempts keep a generic response" do
    5.times do
      post login_path, params: { email: @athlete_user.email, password: "wrong-password" }
      assert_response :unprocessable_entity
      assert_nil session[:user_id]
      assert_includes response.body, "Invalid email or password."
      assert_not_includes response.body, "email was found"
      assert_not_includes response.body, "password was incorrect"
    end
  end

  test "csrf protection rejects cross-origin style post without a token when enabled" do
    sign_in_as @athlete_user
    previous = ApplicationController.allow_forgery_protection
    ApplicationController.allow_forgery_protection = true

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(@tournament), params: registration_params(@athlete, @category), headers: { "HTTP_ORIGIN" => "https://evil.example" }
    end

    assert_response :unprocessable_entity
  ensure
    ApplicationController.allow_forgery_protection = previous
  end

  private

  def create_athlete(user, first_name:, gender:, weight:)
    user.athletes.create!(
      first_name: first_name,
      last_name: "Security",
      date_of_birth: Date.new(2014, 5, 12),
      gender: gender,
      belt: "red",
      weight: weight,
      contact_number: "9876543210",
      emergency_contact_name: "#{first_name} Guardian",
      emergency_contact_phone: "9876543211",
      identity_documents: [identity_image_upload]
    )
  end

  def create_tournament(organizer, name:, opens_at: 1.day.ago, closes_at: 1.day.from_now)
    Tournament.create!(
      name: name,
      organizer: organizer,
      status: :registration_open,
      registration_fee: 900,
      currency: "INR",
      payment_account_name: "Security Tournament Account",
      payment_bank_name: "Security Bank",
      payment_account_number: "1234567890",
      payment_ifsc: "SECU0001234",
      payment_upi_id: "security-organizer@okhdfcbank",
      payment_qr_image: identity_image_upload,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: opens_at,
      registration_closes_at: closes_at
    )
  end

  def registration_params(athlete, category, receipt: payment_receipt_upload)
    {
      registration: {
        athlete_id: athlete.id,
        tournament_category_ids: [category.id],
        registered_weight: athlete.weight,
        payment_receipt: receipt
      }
    }
  end
end
