require "test_helper"

class OrganizerWeightChecksControllerTest < ActionDispatch::IntegrationTest
  test "organizer can search accepted athletes for a closed tournament" do
    organizer = User.create!(name: "Organizer", email: "weigh-search-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "weigh-search-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", association_id: "TKD-100", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Closed Open", organizer: organizer, status: :registration_open, registration_opens_at: 10.days.ago, registration_closes_at: 1.day.ago, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    get organizer_tournament_weight_checks_path(tournament, q: "tkd-100")

    assert_response :success
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, "35-37 kg"
    assert_includes response.body, "Attempt 1"
  end

  test "collaborating organizer can save a passing weight check" do
    owner = User.create!(name: "Owner", email: "weigh-owner@example.test", password: "password123", role: :organizer)
    collaborator = User.create!(name: "Collaborator", email: "weigh-collaborator@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "weigh-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Closed Open", organizer: owner, status: :registration_open, registration_opens_at: 10.days.ago, registration_closes_at: 1.day.ago, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    tournament.tournament_organizers.create!(user: collaborator, added_by: owner)
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)
    sign_in_as collaborator

    assert_difference("RegistrationWeightCheck.count", 1) do
      post organizer_registration_weight_checks_path(registration), params: { registration_weight_check: { weight: 37.0 } }
    end

    assert_redirected_to organizer_tournament_weight_checks_path(tournament)
    assert_predicate registration.reload, :weight_verified?
    assert_equal collaborator, registration.registration_action_logs.last.actor
  end

  test "non manager cannot access tournament weight check" do
    organizer = User.create!(name: "Organizer", email: "weigh-owned-organizer@example.test", password: "password123", role: :organizer)
    other_user = User.create!(name: "Other", email: "weigh-other@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Closed Open", organizer: organizer, status: :registration_open, registration_opens_at: 10.days.ago, registration_closes_at: 1.day.ago, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    sign_in_as other_user

    get organizer_tournament_weight_checks_path(tournament)

    assert_response :not_found
  end
end
