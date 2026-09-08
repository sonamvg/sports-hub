require "test_helper"

class OrganizerWeightChecksControllerTest < ActionDispatch::IntegrationTest
  test "organizer can search accepted athletes for a closed tournament" do
    organizer = User.create!(name: "Organizer", email: "weigh-search-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "weigh-search-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", association_id: "TKD-100", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Closed Open", organizer: organizer, status: :registration_open, registration_opens_at: 10.days.ago, registration_closes_at: 1.day.ago, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
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
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)
    sign_in_as collaborator

    assert_difference("RegistrationWeightCheck.count", 1) do
      post organizer_registration_weight_checks_path(registration), params: { registration_weight_check: { weight: 37.0 } }
    end

    assert_redirected_to organizer_tournament_weight_checks_path(tournament, highlight: registration.id)
    assert_predicate registration.reload, :weight_verified?
    assert_equal collaborator, registration.registration_action_logs.last.actor
  end

  test "organizer can browse athletes grouped by category and filter to one category" do
    organizer = User.create!(name: "Organizer", email: "weigh-group-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Grouped Open", organizer: organizer, status: :registration_open, registration_opens_at: 10.days.ago, registration_closes_at: 1.day.ago, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category_one = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 35, weight_max: 37)
    category_two = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 15, age_max: 17, weight_min: 51, weight_max: 55)

    parent_one = User.create!(name: "Parent One", email: "weigh-group-parent-one@example.test", password: "password123", role: :parent)
    athlete_one = parent_one.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament.registrations.create!(athlete: athlete_one, tournament_category: category_one, status: :approved, payment_receipt: payment_receipt_upload)

    parent_two = User.create!(name: "Parent Two", email: "weigh-group-parent-two@example.test", password: "password123", role: :parent)
    athlete_two = parent_two.athletes.create!(first_name: "Vihaan", last_name: "Mehta", date_of_birth: Date.new(2010, 5, 12), gender: "male")
    tournament.registrations.create!(athlete: athlete_two, tournament_category: category_two, status: :approved, payment_receipt: payment_receipt_upload)

    sign_in_as organizer

    get organizer_tournament_weight_checks_path(tournament)

    assert_response :success
    assert_includes response.body, category_one.name
    assert_includes response.body, category_two.name
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, "Vihaan Mehta"
    assert_includes response.body, "All categories"

    get organizer_tournament_weight_checks_path(tournament, category_id: category_one.id)

    assert_response :success
    assert_includes response.body, "Aarohi Shah"
    assert_not_includes response.body, "Vihaan Mehta"
  end

  test "weigh-in closes for a category once its draw has been generated" do
    organizer = User.create!(name: "Organizer", email: "weigh-draw-lock-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Draw Lock Open", organizer: organizer, status: :registration_open, registration_opens_at: 10.days.ago, registration_closes_at: 1.day.ago, start_date: 2.days.from_now.to_date, end_date: 3.days.from_now.to_date)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 18)
    registration_one = create_weight_verified_registration(tournament: tournament, category: category, email: "weigh-draw-lock-one@example.test")
    create_weight_verified_registration(tournament: tournament, category: category, email: "weigh-draw-lock-two@example.test")

    # A third, still-approved (not yet weighed in) athlete in the same category
    parent_three = User.create!(name: "Parent Three", email: "weigh-draw-lock-parent-three@example.test", password: "password123", role: :parent)
    athlete_three = parent_three.athletes.create!(first_name: "Kabir", last_name: "Rao", date_of_birth: Date.new(1995, 1, 1), gender: "male")
    registration_three = tournament.registrations.create!(athlete: athlete_three, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)

    assert BracketGenerator.new(category).call.success?
    sign_in_as organizer

    get organizer_tournament_weight_checks_path(tournament)

    assert_response :success
    assert_includes response.body, "Draw already set"
    assert_not registration_one.reload.weight_check_attempts_remaining?
    assert_not registration_three.reload.weight_check_attempts_remaining?

    assert_no_difference("RegistrationWeightCheck.count") do
      post organizer_registration_weight_checks_path(registration_three), params: { registration_weight_check: { weight: 70 } }
    end

    assert_includes flash[:alert].to_s, "locked"
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
