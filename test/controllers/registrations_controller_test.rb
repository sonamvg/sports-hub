require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.test", password: "password123", role: :organizer)
    @parent = User.create!(name: "Parent", email: "parent@example.test", password: "password123", role: :parent)
    sign_in_as @parent
  end

  test "registration form is blocked when tournament is not accepting registrations" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_closed,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )

    get new_tournament_registration_path(tournament)

    assert_redirected_to tournament_path(tournament)
    assert_equal "Registration is not open for this tournament.", flash[:alert]
  end

  test "registration create is blocked when registration window has closed" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 3.days.ago,
      registration_closes_at: 1.day.ago
    )
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [category.id],
          registered_weight: 39
        }
      }
    end

    assert_redirected_to tournament_path(tournament)
    assert_equal "Registration is not open for this tournament.", flash[:alert]
  end

  test "registration create shows validation when athlete is missing" do
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: "",
          tournament_category_id: category.id,
          registered_weight: 39
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Athlete must be selected"
    assert_includes response.body, "Add athlete"
  end

  test "registration create highlights the category field directly when no category is selected" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [""],
          registered_weight: 39
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Tournament category must include at least one category"
    assert_includes response.body, "category-picker-invalid"
  end

  test "registration form does not show save and pay later option" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    get new_tournament_registration_path(tournament)

    assert_response :success
    assert_not_includes response.body, "Save and pay later"
    assert_includes response.body, "Submit registration"

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [category.id],
          registered_weight: 39
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Payment receipt must be uploaded"
  end

  test "athlete registration does not offer adding another athlete" do
    athlete_user = User.create!(name: "Athlete User", email: "single-athlete-registration@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    sign_in_as athlete_user

    get new_tournament_registration_path(tournament)

    assert_response :success
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, "registration_athlete_id"
    assert_includes response.body, "value=\"#{athlete.id}\""
    assert_not_includes response.body, "Choose athlete"
    assert_not_includes response.body, "Add another athlete"
  end

  test "registration form resets category picker when academy owner changes athlete" do
    owner = User.create!(name: "Academy Owner", email: "reset-owner@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Owned Academy", city: "Pune", status: :approved, owner: owner)
    first_user = User.create!(name: "First Athlete", email: "first-reset-athlete@example.test", password: "password123", role: :athlete)
    second_user = User.create!(name: "Second Athlete", email: "second-reset-athlete@example.test", password: "password123", role: :athlete)
    first_athlete = first_user.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    second_user.athletes.create!(academy: academy, first_name: "Vihaan", last_name: "Mehta", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    sign_in_as owner

    get new_tournament_registration_path(tournament, athlete_id: first_athlete.id, category_id: category.id)

    assert_response :success
    assert_includes response.body, "data-athlete-select"
    assert_includes response.body, "resetCategoryPicker"
    assert_includes response.body, "selected=\"selected\" value=\"#{category.id}\""
  end

  test "registration create requires receipt when submitting multiple categories" do
    athlete = @parent.athletes.create!(
      first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female",
      contact_number: "9123456789", emergency_contact_name: "Priya Shah", emergency_contact_phone: "9876543210", identity_document: identity_image_upload
    )
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      registration_fee: 750,
      currency: "INR",
      payment_account_name: "Pune Taekwondo Association",
      payment_bank_name: "Demo Bank",
      payment_account_number: "1234567890",
      payment_ifsc: "DEMO0001234",
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: nil, weight_max: 41)
    second_category = tournament.tournament_categories.find_or_create_by!(event_type: "poomsae", gender: "female", age_min: 12, age_max: 14)

    get new_tournament_registration_path(tournament)
    assert_response :success
    assert_includes response.body, "Kyorugi Female Age 12-14 U41 - INR 750"
    assert_includes response.body, "Poomsae Female Age 12-14 - INR 750"
    assert_includes response.body, "Total amount to pay"
    assert_includes response.body, "Secure payment details"
    assert_includes response.body, "1234567890"

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [category.id, second_category.id],
          registered_weight: 39
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Payment receipt must be uploaded"

    assert_difference("Registration.pending.count", 2) do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [category.id, second_category.id],
          registered_weight: 39,
          payment_receipt: payment_receipt_upload
        }
      }
    end

    registrations = Registration.where(athlete: athlete, tournament: tournament)
    assert registrations.all? { |registration| registration.payment_receipt.attached? }
    assert_equal [BigDecimal("750.0"), BigDecimal("750.0")], registrations.order(:fee_amount).pluck(:fee_amount)
    assert_equal ["INR"], registrations.distinct.pluck(:fee_currency)
    assert_equal 1, registrations.map { |registration| registration.payment_receipt.blob_id }.uniq.size
    assert_equal 1, registrations.pluck(:submission_batch_id).uniq.size
    assert registrations.pluck(:submission_batch_id).all?(&:present?)
  end

  test "registration create succeeds without a receipt when tournament is free" do
    athlete = @parent.athletes.create!(
      first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female",
      contact_number: "9123456789", emergency_contact_name: "Priya Shah", emergency_contact_phone: "9876543210", identity_document: identity_image_upload
    )
    tournament = Tournament.create!(
      name: "Community Open",
      organizer: @organizer,
      status: :registration_open,
      registration_fee: 0,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    get new_tournament_registration_path(tournament)
    assert_response :success
    assert_includes response.body, "This tournament is free to enter. No payment or receipt is required."
    assert_not_includes response.body, "Secure payment details"

    assert_difference("Registration.pending.count", 1) do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [category.id],
          registered_weight: 39
        }
      }
    end

    registration = Registration.find_by(athlete: athlete, tournament: tournament)
    assert_not registration.payment_receipt.attached?
    assert_equal BigDecimal("0"), registration.fee_amount
  end

  test "academy owner can register an owned academy athlete and category picker uses add more flow" do
    owner = User.create!(name: "Academy Owner", email: "register-owner@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Owned Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "register-academy-athlete@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(
      academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female",
      contact_number: "9123456789", emergency_contact_name: "Priya Shah", emergency_contact_phone: "9876543210", identity_document: identity_image_upload
    )
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    sign_in_as owner

    get new_tournament_registration_path(tournament)
    assert_response :success
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, "data-category-picker"
    assert_includes response.body, "Do you want to add more categories?"
    assert_includes response.body, "Delete"

    assert_difference("Registration.pending.count", 1) do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [category.id],
          registered_weight: 39,
          payment_receipt: payment_receipt_upload
        }
      }
    end
  end

  test "registration create is blocked when athlete profile is missing contact number and identity document" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [category.id],
          registered_weight: 39,
          payment_receipt: payment_receipt_upload
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "profile must include a contact number and identity document before registering"
  end

  test "resubmitting an already reviewed category does not reset its status and skips it with a notice" do
    athlete = @parent.athletes.create!(
      first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female",
      contact_number: "9123456789", emergency_contact_name: "Priya Shah", emergency_contact_phone: "9876543210", identity_document: identity_image_upload
    )
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    reviewed_category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    new_category = tournament.tournament_categories.find_or_create_by!(event_type: "poomsae", gender: "female", age_min: 12, age_max: 14)
    reviewed_registration = tournament.registrations.create!(athlete: athlete, tournament_category: reviewed_category, status: :approved, payment_receipt: payment_receipt_upload)

    assert_difference("Registration.pending.count", 1) do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [reviewed_category.id, new_category.id],
          registered_weight: 39,
          payment_receipt: payment_receipt_upload
        }
      }
    end

    assert_redirected_to tournament_registrations_path(tournament)
    assert_match(/already have a decision/, flash[:notice])
    assert_predicate reviewed_registration.reload, :approved?
  end

  test "registration create is blocked when every selected category already has a decision" do
    athlete = @parent.athletes.create!(
      first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female",
      contact_number: "9123456789", emergency_contact_name: "Priya Shah", emergency_contact_phone: "9876543210", identity_document: identity_image_upload
    )
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    reviewed_category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    reviewed_registration = tournament.registrations.create!(athlete: athlete, tournament_category: reviewed_category, status: :rejected, payment_receipt: payment_receipt_upload)

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [reviewed_category.id],
          registered_weight: 39,
          payment_receipt: payment_receipt_upload
        }
      }
    end

    assert_response :unprocessable_entity
    assert_predicate reviewed_registration.reload, :rejected?
  end

  test "submitting the same category twice in one request creates only one registration" do
    athlete = @parent.athletes.create!(
      first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female",
      contact_number: "9123456789", emergency_contact_name: "Priya Shah", emergency_contact_phone: "9876543210", identity_document: identity_image_upload
    )
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    assert_difference("Registration.count", 1) do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [category.id.to_s, category.id.to_s],
          registered_weight: 39,
          payment_receipt: payment_receipt_upload
        }
      }
    end

    assert_response :redirect
  end

  test "registration create shows a friendly error when a selected category no longer exists" do
    athlete = @parent.athletes.create!(
      first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female",
      contact_number: "9123456789", emergency_contact_name: "Priya Shah", emergency_contact_phone: "9876543210", identity_document: identity_image_upload
    )
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    removed_category_id = category.id
    category.destroy!

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: {
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [removed_category_id.to_s],
          registered_weight: 39,
          payment_receipt: payment_receipt_upload
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "no longer available"
  end
end
