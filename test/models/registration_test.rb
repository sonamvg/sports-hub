require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  test "category must belong to selected tournament" do
    organizer = User.create!(name: "Organizer", email: "organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Local Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    other_tournament = Tournament.create!(name: "Other Open", organizer: organizer, start_date: Date.new(2026, 11, 18), end_date: Date.new(2026, 11, 19))
    category = other_tournament.tournament_categories.find_or_create_by!(name: "Cadet Female U41", event_type: "kyorugi")

    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category)

    assert_not registration.valid?
    assert_includes registration.errors[:tournament_category], "must belong to the selected tournament"
  end

  test "allows registration without a payment receipt when tournament is free" do
    organizer = User.create!(name: "Organizer", email: "free-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "free-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Free Open", organizer: organizer, registration_fee: 0, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14)

    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category)

    assert registration.valid?
  end

  test "still requires a payment receipt when tournament fee is unset" do
    organizer = User.create!(name: "Organizer", email: "unset-fee-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "unset-fee-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Unset Fee Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14)

    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category)

    assert_not registration.valid?
    assert_includes registration.errors[:payment_receipt], "must be uploaded"
  end

  test "snapshots fee_amount from the group fee for a pair or team poomsae registration" do
    organizer = User.create!(name: "Organizer", email: "group-fee-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "group-fee-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Group Fee Open", organizer: organizer, registration_fee: 500, group_registration_fee: 1500, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)

    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)
    registration.valid?

    assert_equal 1500, registration.fee_amount
  end

  test "a free individual fee does not exempt a paid group registration from needing a receipt, and vice versa" do
    organizer = User.create!(name: "Organizer", email: "mixed-fee-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "mixed-fee-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Mixed Fee Open", organizer: organizer, registration_fee: 0, group_registration_fee: 1500, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    kyorugi_category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14)
    group_category = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)

    free_registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: kyorugi_category)
    assert free_registration.valid?

    paid_registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: group_category)
    assert_not paid_registration.valid?
    assert_includes paid_registration.errors[:payment_receipt], "must be uploaded"
  end

  test "rejects a zero, negative, or out-of-range registered weight" do
    organizer = User.create!(name: "Organizer", email: "weight-validation-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "weight-validation-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Weight Validation Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14)

    zero = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, registered_weight: 0)
    assert_not zero.valid?
    assert_includes zero.errors[:registered_weight], "must be greater than 0"

    too_large = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, registered_weight: 1000)
    assert_not too_large.valid?
    assert_includes too_large.errors[:registered_weight], "must be less than or equal to 999.99"
  end

  test "rejects unsupported payment receipt upload type" do
    organizer = User.create!(name: "Organizer", email: "receipt-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "receipt-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Receipt Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(name: "Cadet Female U41", event_type: "kyorugi")
    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, payment_receipt: invalid_text_upload)

    assert_not registration.valid?
    assert_includes registration.errors[:payment_receipt], "must be a JPG, PNG, WebP, or PDF file"
  end

  test "rejects a payment receipt whose content does not match its declared image type" do
    organizer = User.create!(name: "Organizer", email: "spoofed-receipt-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "spoofed-receipt-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Receipt Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(name: "Cadet Female U41", event_type: "kyorugi")
    spoofed_upload = Rack::Test::UploadedFile.new(StringIO.new("#!/bin/bash\necho pwned\n"), "image/png", original_filename: "receipt.png")
    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, payment_receipt: spoofed_upload)

    assert_not registration.valid?
    assert_includes registration.errors[:payment_receipt], "must be a JPG, PNG, WebP, or PDF file"
  end

  test "rejects payment receipt uploads over five megabytes" do
    organizer = User.create!(name: "Organizer", email: "large-receipt-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "large-receipt-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Large Receipt Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(name: "Cadet Female U41", event_type: "kyorugi")
    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, payment_receipt: oversized_upload)

    assert_not registration.valid?
    assert_includes registration.errors[:payment_receipt], "must be 5 MB or smaller"
  end

  test "rejects registration when athlete gender does not match category" do
    organizer = User.create!(name: "Organizer", email: "gender-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "gender-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Gender Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14)
    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)

    assert_not registration.valid?
    assert_includes registration.errors[:base], "athlete's gender does not match this category"
  end

  test "rejects registration when athlete age does not match category" do
    organizer = User.create!(name: "Organizer", email: "age-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "age-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2010, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Age Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14)
    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)

    assert_not registration.valid?
    assert_includes registration.errors[:base], "athlete's age does not match this category"
  end

  test "rejects registration when athlete belt does not match category" do
    organizer = User.create!(name: "Organizer", email: "belt-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "belt-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", belt: "white")
    tournament = Tournament.create!(name: "Belt Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, belt_min: "blue")
    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)

    assert_not registration.valid?
    assert_includes registration.errors[:base], "athlete's belt rank does not match this category"
  end

  test "rejects registration when declared weight does not match category" do
    organizer = User.create!(name: "Organizer", email: "declared-weight-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "declared-weight-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Declared Weight Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, registered_weight: 50, payment_receipt: payment_receipt_upload)

    assert_not registration.valid?
    assert_includes registration.errors[:base], "athlete's weight does not match this category"
  end

  test "allows registration without a declared weight even when category has a weight range" do
    organizer = User.create!(name: "Organizer", email: "no-weight-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "no-weight-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "No Weight Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)

    assert registration.valid?
  end

  test "passing weight check moves accepted registration to weight verified and logs actor" do
    organizer = User.create!(name: "Organizer", email: "weight-pass-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "weight-pass-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Local Open", organizer: organizer, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)

    assert_difference("RegistrationActionLog.count", 1) do
      registration.registration_weight_checks.create!(checked_by: organizer, weight: 36.8)
    end

    assert_predicate registration.reload, :weight_verified?
    assert_equal "weight_verified", registration.registration_action_logs.last.action
    assert_equal organizer, registration.registration_action_logs.last.actor
  end

  test "three failed weight checks disqualify registration" do
    organizer = User.create!(name: "Organizer", email: "weight-fail-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "weight-fail-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Reyansh", last_name: "Mehta", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    tournament = Tournament.create!(name: "Local Invitational", organizer: organizer, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)

    assert_no_difference("RegistrationActionLog.count") do
      registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.5)
      registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.3)
    end

    assert_difference("RegistrationActionLog.count", 1) do
      registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.0)
    end

    assert_predicate registration.reload, :disqualified?
    assert_equal [1, 2, 3], registration.registration_weight_checks.order(:attempt_number).pluck(:attempt_number)
    assert_equal "disqualified", registration.registration_action_logs.last.action
  end

  test "pending registration cannot be weight checked" do
    organizer = User.create!(name: "Organizer", email: "weight-pending-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "weight-pending-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Nina", last_name: "Kapoor", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Local Trials", organizer: organizer, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)

    weight_check = registration.registration_weight_checks.build(checked_by: organizer, weight: 36)

    assert_not weight_check.valid?
    assert_includes weight_check.errors[:registration], "must be accepted before weight check"
  end

  test "third failed weight check pauses on a decision instead of disqualifying when the tournament allows category change" do
    organizer = User.create!(name: "Organizer", email: "decision-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "decision-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Reyansh", last_name: "Mehta", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    tournament = Tournament.create!(name: "Decision Open", organizer: organizer, allow_category_change_at_weigh_in: true, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)

    assert_not registration.weight_check_decision_pending?

    assert_no_difference("RegistrationActionLog.count") do
      registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.5)
      registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.3)
      registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.0)
    end

    registration.reload
    assert_predicate registration, :approved?
    assert registration.weight_check_decision_pending?
  end

  test "eligible_category_change_targets is scoped to sibling weight brackets in the same division" do
    organizer = User.create!(name: "Organizer", email: "targets-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Targets Open", organizer: organizer, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    sibling_lower = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 33, weight_max: 35)
    sibling_higher = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 37, weight_max: 41)
    other_division = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    other_event_type = tournament.tournament_categories.find_or_create_by!(event_type: "individual_poomsae", gender: "male", age_min: 12, age_max: 14)
    athlete_user = User.create!(name: "Parent", email: "targets-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Reyansh", last_name: "Mehta", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)

    targets = registration.eligible_category_change_targets

    assert_includes targets, sibling_lower
    assert_includes targets, sibling_higher
    assert_not_includes targets, category
    assert_not_includes targets, other_division
    assert_not_includes targets, other_event_type
  end

  test "recommended_category_change_target picks the sibling closest to the athlete's last measured weight" do
    organizer = User.create!(name: "Organizer", email: "recommend-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Recommend Open", organizer: organizer, allow_category_change_at_weigh_in: true, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    close_sibling = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 37, weight_max: 41)
    far_sibling = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 45, weight_max: 49)
    athlete_user = User.create!(name: "Parent", email: "recommend-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Reyansh", last_name: "Mehta", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)
    registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.5)
    registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.3)
    registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.0)

    assert_equal close_sibling, registration.reload.recommended_category_change_target
    assert_not_equal far_sibling, registration.recommended_category_change_target
  end

  test "move_to_category! withdraws the old registration and creates a fresh approved one in the new category" do
    organizer = User.create!(name: "Organizer", email: "move-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Move Open", organizer: organizer, allow_category_change_at_weigh_in: true, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    target_category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 37, weight_max: 41)
    athlete_user = User.create!(name: "Parent", email: "move-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Reyansh", last_name: "Mehta", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)
    registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.5)
    registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.3)
    registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.0)

    new_registration = registration.move_to_category!(category: target_category, actor: organizer)

    assert_predicate registration.reload, :withdrawn?
    assert_equal "withdrawn", registration.registration_action_logs.last.action

    assert_predicate new_registration, :approved?
    assert_equal target_category, new_registration.tournament_category
    assert_equal registration, new_registration.moved_from_registration
    assert_equal registration.fee_amount, new_registration.fee_amount
    assert_equal 38.0.to_d, new_registration.registered_weight
    assert new_registration.payment_receipt.attached?
    assert_empty new_registration.registration_weight_checks
    assert_equal "approved", new_registration.registration_action_logs.last.action
  end

end
