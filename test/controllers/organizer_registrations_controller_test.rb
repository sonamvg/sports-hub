require "test_helper"

class OrganizerRegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "organizer sees only registrations for owned tournaments" do
    organizer = User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :organizer)
    other_organizer = User.create!(name: "Other Organizer", email: "other-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "athlete-user@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")

    owned_tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    owned_category = owned_tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    owned_registration = owned_tournament.registrations.create!(athlete: athlete, tournament_category: owned_category, payment_receipt: payment_receipt_upload)

    other_tournament = Tournament.create!(name: "Other Open", organizer: other_organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    other_category = other_tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    other_tournament.registrations.create!(athlete: athlete, tournament_category: other_category, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    get organizer_registrations_path

    assert_response :success
    assert_includes response.body, owned_registration.tournament.name
    assert_not_includes response.body, other_tournament.name
  end

  test "registrations are ordered pending accepted denied and include receipt review actions" do
    organizer = User.create!(name: "Organizer", email: "ordering-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "ordering-athlete@example.test", password: "password123", role: :parent)
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    pending_category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    approved_category = tournament.tournament_categories.create!(event_type: "poomsae", gender: "female", age_min: 12, age_max: 14)
    rejected_category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_max: 45)
    pending_athlete = athlete_user.athletes.create!(first_name: "Pending", last_name: "Athlete", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    approved_athlete = athlete_user.athletes.create!(first_name: "Accepted", last_name: "Athlete", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    rejected_athlete = athlete_user.athletes.create!(first_name: "Denied", last_name: "Athlete", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    tournament.registrations.create!(athlete: approved_athlete, tournament_category: approved_category, status: :approved, payment_receipt: payment_receipt_upload)
    tournament.registrations.create!(athlete: rejected_athlete, tournament_category: rejected_category, status: :rejected, payment_receipt: payment_receipt_upload)
    tournament.registrations.create!(athlete: pending_athlete, tournament_category: pending_category, status: :pending, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    get organizer_registrations_path

    assert_response :success
    assert_includes response.body, "View receipt"
    assert_includes response.body, "Accept"
    assert_includes response.body, "Deny"
    assert_operator response.body.index("Pending Athlete"), :<, response.body.index("Accepted Athlete")
    assert_operator response.body.index("Accepted Athlete"), :<, response.body.index("Denied Athlete")
  end

  test "organizer accepting registration creates action log" do
    organizer = User.create!(name: "Organizer", email: "accept-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "accept-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    assert_difference("RegistrationActionLog.count", 1) do
      patch approve_organizer_registration_path(registration)
    end

    assert_redirected_to organizer_registrations_path
    assert_predicate registration.reload, :approved?
    log = registration.registration_action_logs.sole
    assert_equal organizer, log.actor
    assert_equal "approved", log.action
    assert_equal "pending", log.from_status
    assert_equal "approved", log.to_status
  end

  test "super admin only sees action log when assigned to the tournament" do
    organizer = User.create!(name: "Organizer", email: "log-organizer@example.test", password: "password123", role: :organizer)
    super_admin = User.create!(name: "Super Admin", email: "log-admin@example.test", password: "password123", role: :super_admin)
    athlete_user = User.create!(name: "Athlete User", email: "log-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    tournament.tournament_organizers.create!(user: super_admin, added_by: organizer)
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)
    registration.review!(actor: organizer, status: :rejected)

    sign_in_as organizer
    get organizer_registration_path(registration)
    assert_response :success
    assert_not_includes response.body, "Action log"

    sign_in_as super_admin
    get organizer_registration_path(registration)
    assert_response :success
    assert_includes response.body, "Action log"
    assert_includes response.body, "Organizer"
    assert_includes response.body, "Pending → Rejected"
  end

  test "unassigned super admin is not the approval recipient for tournament registrations" do
    organizer = User.create!(name: "Organizer", email: "approval-owner@example.test", password: "password123", role: :organizer)
    super_admin = User.create!(name: "Super Admin", email: "approval-admin@example.test", password: "password123", role: :super_admin)
    athlete_user = User.create!(name: "Athlete User", email: "approval-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)
    sign_in_as super_admin

    get organizer_registrations_path
    assert_response :success
    assert_not_includes response.body, "Aarohi Shah"

    patch approve_organizer_registration_path(registration)
    assert_response :not_found
    assert_predicate registration.reload, :pending?
  end
end
