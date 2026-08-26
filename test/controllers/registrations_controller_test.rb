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
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

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
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

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

  test "registration create saves draft selections without receipt" do
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
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    assert_difference("Registration.draft.count", 1) do
      post tournament_registrations_path(tournament), params: {
        commit: "Save and pay later",
        registration: {
          athlete_id: athlete.id,
          tournament_category_ids: [category.id],
          registered_weight: 39
        }
      }
    end

    assert_redirected_to tournament_registrations_path(tournament)
    assert_not_predicate Registration.order(:created_at).last.payment_receipt, :attached?
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
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    tournament.registrations.create!(athlete: first_athlete, tournament_category: category, status: :draft)
    sign_in_as owner

    get new_tournament_registration_path(tournament, athlete_id: first_athlete.id)

    assert_response :success
    assert_includes response.body, "data-athlete-select"
    assert_includes response.body, "resetCategoryPicker"
    assert_includes response.body, "selected=\"selected\" value=\"#{category.id}\""
  end

  test "registration create requires receipt when submitting multiple categories" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
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
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41, registration_fee: 1000)
    second_category = tournament.tournament_categories.create!(event_type: "poomsae", gender: "female", age_min: 12, age_max: 14, registration_fee: 1200)

    get new_tournament_registration_path(tournament)
    assert_response :success
    assert_includes response.body, "Kyorugi Female Age 12-14 U41 - INR 1000"
    assert_includes response.body, "Poomsae Female Age 12-14 - INR 1200"
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

    assert Registration.where(athlete: athlete, tournament: tournament).all? { |registration| registration.payment_receipt.attached? }
    assert_equal [BigDecimal("1000.0"), BigDecimal("1200.0")], Registration.where(athlete: athlete, tournament: tournament).order(:fee_amount).pluck(:fee_amount)
    assert_equal ["INR"], Registration.where(athlete: athlete, tournament: tournament).distinct.pluck(:fee_currency)
  end

  test "academy owner can register an owned academy athlete and category picker uses add more flow" do
    owner = User.create!(name: "Academy Owner", email: "register-owner@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Owned Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "register-academy-athlete@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6),
      registration_opens_at: 1.day.ago,
      registration_closes_at: 1.day.from_now
    )
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
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
end
