require "test_helper"

class OrganizerWeightCheckDecisionsControllerTest < ActionDispatch::IntegrationTest
  def decision_pending_registration(organizer:, allow_category_change: true)
    tournament = Tournament.create!(name: "Decision Open", organizer: organizer, allow_category_change_at_weigh_in: allow_category_change,
      status: :registration_open, registration_opens_at: 10.days.ago, registration_closes_at: 1.day.ago,
      start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    parent = User.create!(name: "Parent", email: "decision-ctrl-parent-#{SecureRandom.hex(4)}@example.test", password: "password123", role: :parent)
    athlete = parent.athletes.create!(first_name: "Reyansh", last_name: "Mehta", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)
    registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.5)
    registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.3)
    registration.registration_weight_checks.create!(checked_by: organizer, weight: 38.0)
    [tournament, category, registration]
  end

  test "organizer can disqualify a decision-pending registration" do
    organizer = User.create!(name: "Organizer", email: "decision-ctrl-disqualify-organizer@example.test", password: "password123", role: :organizer)
    _tournament, _category, registration = decision_pending_registration(organizer: organizer)
    sign_in_as organizer

    patch disqualify_organizer_registration_weight_check_decision_path(registration)

    assert_redirected_to organizer_tournament_weight_checks_path(registration.tournament)
    assert_predicate registration.reload, :disqualified?
  end

  test "organizer can move a decision-pending registration to a sibling category" do
    organizer = User.create!(name: "Organizer", email: "decision-ctrl-move-organizer@example.test", password: "password123", role: :organizer)
    tournament, _category, registration = decision_pending_registration(organizer: organizer)
    target_category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 37, weight_max: 41)
    sign_in_as organizer

    assert_difference("Registration.count", 1) do
      patch change_category_organizer_registration_weight_check_decision_path(registration), params: { tournament_category_id: target_category.id }
    end

    assert_predicate registration.reload, :withdrawn?
    new_registration = Registration.order(:created_at).last
    assert_equal target_category, new_registration.tournament_category
    assert_redirected_to organizer_tournament_weight_checks_path(tournament, highlight: new_registration.id)
  end

  test "change_category rejects a category outside eligible targets" do
    organizer = User.create!(name: "Organizer", email: "decision-ctrl-invalid-organizer@example.test", password: "password123", role: :organizer)
    tournament, _category, registration = decision_pending_registration(organizer: organizer)
    unrelated_category = tournament.tournament_categories.find_or_create_by!(event_type: "individual_poomsae", gender: "male", age_min: 12, age_max: 14)
    sign_in_as organizer

    assert_no_difference("Registration.count") do
      patch change_category_organizer_registration_weight_check_decision_path(registration), params: { tournament_category_id: unrelated_category.id }
    end

    assert_redirected_to organizer_tournament_weight_checks_path(tournament)
    assert_predicate registration.reload, :approved?
  end

  test "decision actions are rejected when the registration is not decision-pending" do
    organizer = User.create!(name: "Organizer", email: "decision-ctrl-not-pending-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Not Pending Open", organizer: organizer, allow_category_change_at_weigh_in: true,
      status: :registration_open, registration_opens_at: 10.days.ago, registration_closes_at: 1.day.ago,
      start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    parent = User.create!(name: "Parent", email: "decision-ctrl-not-pending-parent@example.test", password: "password123", role: :parent)
    athlete = parent.athletes.create!(first_name: "Reyansh", last_name: "Mehta", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    patch disqualify_organizer_registration_weight_check_decision_path(registration)

    assert_redirected_to organizer_tournament_weight_checks_path(tournament)
    assert_predicate registration.reload, :approved?
  end

  test "non manager cannot act on another organizer's weight check decision" do
    owner = User.create!(name: "Owner", email: "decision-ctrl-owner@example.test", password: "password123", role: :organizer)
    other_user = User.create!(name: "Other", email: "decision-ctrl-other@example.test", password: "password123", role: :organizer)
    _tournament, _category, registration = decision_pending_registration(organizer: owner)
    sign_in_as other_user

    patch disqualify_organizer_registration_weight_check_decision_path(registration)

    assert_response :not_found
  end
end
