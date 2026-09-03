require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  test "category must belong to selected tournament" do
    organizer = User.create!(name: "Organizer", email: "organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Local Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    other_tournament = Tournament.create!(name: "Other Open", organizer: organizer, start_date: Date.new(2026, 11, 18), end_date: Date.new(2026, 11, 19))
    category = other_tournament.tournament_categories.create!(name: "Cadet Female U41", event_type: "kyorugi")

    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category)

    assert_not registration.valid?
    assert_includes registration.errors[:tournament_category], "must belong to the selected tournament"
  end

  test "rejects unsupported payment receipt upload type" do
    organizer = User.create!(name: "Organizer", email: "receipt-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "receipt-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Receipt Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.create!(name: "Cadet Female U41", event_type: "kyorugi")
    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, payment_receipt: invalid_text_upload)

    assert_not registration.valid?
    assert_includes registration.errors[:payment_receipt], "must be a JPG, PNG, WebP, or PDF file"
  end

  test "rejects payment receipt uploads over five megabytes" do
    organizer = User.create!(name: "Organizer", email: "large-receipt-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "large-receipt-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Large Receipt Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    category = tournament.tournament_categories.create!(name: "Cadet Female U41", event_type: "kyorugi")
    registration = Registration.new(tournament: tournament, athlete: athlete, tournament_category: category, payment_receipt: oversized_upload)

    assert_not registration.valid?
    assert_includes registration.errors[:payment_receipt], "must be 5 MB or smaller"
  end

  test "passing weight check moves accepted registration to weight verified and logs actor" do
    organizer = User.create!(name: "Organizer", email: "weight-pass-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Parent", email: "weight-pass-parent@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Local Open", organizer: organizer, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
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
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
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
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)

    weight_check = registration.registration_weight_checks.build(checked_by: organizer, weight: 36)

    assert_not weight_check.valid?
    assert_includes weight_check.errors[:registration], "must be accepted before weight check"
  end

end
