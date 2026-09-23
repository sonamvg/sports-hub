require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.test", password: "password123", role: :organizer)
    @parent = User.create!(name: "Parent", email: "parent@example.test", password: "password123", role: :parent)
    sign_in_as @parent
  end

  def open_tournament(**attributes)
    Tournament.create!(
      {
        name: "Pune Invitational",
        organizer: @organizer,
        status: :registration_open,
        start_date: Date.new(2026, 12, 5),
        end_date: Date.new(2026, 12, 6),
        registration_opens_at: 1.day.ago,
        registration_closes_at: 1.day.from_now,
        payment_upi_id: "academy@upi"
      }.merge(attributes)
    )
  end

  test "registration entry point is blocked when tournament is not accepting registrations" do
    tournament = Tournament.create!(name: "Pune Invitational", organizer: @organizer, status: :registration_closed, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))

    get new_tournament_registration_path(tournament)

    assert_redirected_to tournament_path(tournament)
    assert_equal "Registration is not open for this tournament.", flash[:alert]
  end

  test "new renders the direct self-registration form for an athlete-role user, with no Pair/Team Poomsae option" do
    athlete_user = User.create!(name: "Aarohi Shah", email: "athlete-new@example.test", password: "password123", role: :athlete)
    athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2013, 5, 12), gender: "female", weight: 34.2)
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    pair = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)
    sign_in_as athlete_user

    get new_tournament_registration_path(tournament)

    assert_response :success
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, category.name
    assert_not_includes response.body, pair.name
    assert_not_includes response.body, "Register a Pair or Team Poomsae entry"
  end

  test "new redirects an athlete with no profile yet to profile setup" do
    athlete_user = User.create!(name: "Aarohi Shah", email: "athlete-noprofile@example.test", password: "password123", role: :athlete)
    tournament = open_tournament
    sign_in_as athlete_user

    get new_tournament_registration_path(tournament)

    # Handled globally by ApplicationController#require_athlete_profile_completion.
    assert_redirected_to new_athlete_path(profile_setup: true)
  end

  test "new shows both entry options for an academy owner" do
    owner = User.create!(name: "Owner", email: "owner-new@example.test", password: "password123", role: :academy_owner)
    academy = owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    owner.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = open_tournament
    sign_in_as owner

    get new_tournament_registration_path(tournament)

    assert_response :success
    assert_includes response.body, "Register for individual categories"
    assert_includes response.body, "Register a Pair or Team Poomsae entry"
  end

  test "athlete direct registration creates pending registrations immediately, no draft/cart involved" do
    athlete_user = User.create!(name: "Aarohi Shah", email: "athlete-create@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2013, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 0)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37, registration_fee: 0)
    sign_in_as athlete_user

    assert_difference("Registration.count", 1) do
      post tournament_registrations_path(tournament), params: {
        tournament_category_ids: [category.id],
        registered_weight: 34
      }
    end

    assert_redirected_to tournament_registrations_path(tournament)
    registration = Registration.last
    assert_predicate registration, :pending?
    assert_equal athlete, registration.athlete
    assert_equal category, registration.tournament_category
  end

  test "athlete direct registration supports selecting multiple individual categories at once" do
    athlete_user = User.create!(name: "Aarohi Shah", email: "athlete-multi@example.test", password: "password123", role: :athlete)
    athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2013, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 0)
    kyorugi = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    poomsae = tournament.tournament_categories.find_or_create_by!(event_type: "individual_poomsae", gender: "female", age_min: 12, age_max: 14)
    sign_in_as athlete_user

    assert_difference("Registration.count", 2) do
      post tournament_registrations_path(tournament), params: { tournament_category_ids: [kyorugi.id, poomsae.id] }
    end

    assert_redirected_to tournament_registrations_path(tournament)
    assert Registration.last(2).all?(&:pending?)
  end

  test "athlete direct registration cannot be used to register a pair or team poomsae category" do
    athlete_user = User.create!(name: "Aarohi Shah", email: "athlete-nogroup@example.test", password: "password123", role: :athlete)
    athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2013, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament
    pair = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)
    sign_in_as athlete_user

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: { tournament_category_ids: [pair.id] }
    end

    assert_response :unprocessable_entity
  end

  test "athlete direct registration requires a receipt for a paid category" do
    athlete_user = User.create!(name: "Aarohi Shah", email: "athlete-receipt@example.test", password: "password123", role: :athlete)
    athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2013, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 500)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37, registration_fee: 500)
    sign_in_as athlete_user

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: { tournament_category_ids: [category.id] }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "receipt"
  end

  test "athlete direct registration needs no receipt when the tournament has no payment method (cash payment)" do
    athlete_user = User.create!(name: "Aarohi Shah", email: "athlete-cash@example.test", password: "password123", role: :athlete)
    athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2013, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 500, payment_upi_id: nil)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37, registration_fee: 500)
    sign_in_as athlete_user

    assert_difference("Registration.count", 1) do
      post tournament_registrations_path(tournament), params: { tournament_category_ids: [category.id], payment_note: "Handed cash to organizer at the venue" }
    end

    assert_redirected_to tournament_registrations_path(tournament)
    assert_equal "Handed cash to organizer at the venue", Registration.last.payment_note
  end

  test "athlete direct registration for an already-decided category shows a clear message instead of doing nothing" do
    athlete_user = User.create!(name: "Aarohi Shah", email: "athlete-dup@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2013, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)
    sign_in_as athlete_user

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: { tournament_category_ids: [category.id] }
    end

    assert_redirected_to new_tournament_registration_path(tournament)
    assert_includes flash[:alert], "already have a registration decision"
  end

  test "academy owner cannot use the athlete-only direct registration action" do
    owner = User.create!(name: "Owner", email: "owner-nocreate@example.test", password: "password123", role: :academy_owner)
    academy = owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    owner.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    sign_in_as owner

    assert_no_difference("Registration.count") do
      post tournament_registrations_path(tournament), params: { tournament_category_ids: [category.id] }
    end

    assert_response :not_found
  end

  test "individual screen suggests categories matching the athlete's gender and age with the closest kyorugi bracket recommended" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", weight: 34.2)
    tournament = open_tournament
    close_bracket = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    far_bracket = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 44, weight_max: 47)
    poomsae = tournament.tournament_categories.find_or_create_by!(event_type: "individual_poomsae", gender: "female", age_min: 12, age_max: 14)
    other_age = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 15, age_max: 17, weight_min: 33, weight_max: 37)

    get individual_tournament_registrations_path(tournament, athlete_id: athlete.id)

    assert_response :success
    assert_includes response.body, close_bracket.name
    assert_includes response.body, far_bracket.name
    assert_includes response.body, poomsae.name
    assert_not_includes response.body, other_age.name
  end

  test "individual POST creates draft registrations and proceeds to payment" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)

    assert_difference("Registration.count", 1) do
      post individual_tournament_registrations_path(tournament), params: {
        athlete_id: athlete.id,
        tournament_category_ids: [category.id],
        registered_weight: 34,
        next: "payment"
      }
    end

    assert_redirected_to payment_tournament_registrations_path(tournament)
    registration = Registration.last
    assert_predicate registration, :draft?
    assert_equal athlete, registration.athlete
    assert_equal category, registration.tournament_category
    assert_not_nil registration.submission_batch_id
  end

  test "individual POST with next=group proceeds to the group screen" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)

    post individual_tournament_registrations_path(tournament), params: {
      athlete_id: athlete.id,
      tournament_category_ids: [category.id],
      next: "group"
    }

    assert_redirected_to group_tournament_registrations_path(tournament)
  end

  test "individual POST is invalid without an athlete or category" do
    tournament = open_tournament

    assert_no_difference("Registration.count") do
      post individual_tournament_registrations_path(tournament), params: { athlete_id: "", tournament_category_ids: [""] }
    end

    assert_response :unprocessable_entity
  end

  test "individual screen never offers Pair or Team Poomsae categories" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = open_tournament
    pair = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)

    get individual_tournament_registrations_path(tournament, athlete_id: athlete.id)

    assert_not_includes response.body, pair.name
  end

  test "resubmitting the same athlete and category does not duplicate or disturb an already-decided registration" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    existing = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)

    assert_no_difference("Registration.count") do
      post individual_tournament_registrations_path(tournament), params: {
        athlete_id: athlete.id,
        tournament_category_ids: [category.id],
        next: "payment"
      }
    end

    assert_predicate existing.reload, :approved?
    assert_redirected_to individual_tournament_registrations_path(tournament, athlete_id: athlete.id)
    assert_includes flash[:alert], "already has a registration decision"
  end

  test "duplicate group entry shows a clear error instead of silently doing nothing" do
    owner = User.create!(name: "Owner", email: "owner-dup-group@example.test", password: "password123", role: :academy_owner)
    academy = owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    athlete_one = owner.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    athlete_two = owner.athletes.create!(academy: academy, first_name: "Ishaani", last_name: "Patel", date_of_birth: Date.new(2013, 3, 1), gender: "female", contact_number: "9876543211")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)
    tournament.registrations.create!(athlete: athlete_one, tournament_category: category, status: :approved, payment_receipt: payment_receipt_upload)
    sign_in_as owner

    assert_no_difference("Registration.count") do
      post group_tournament_registrations_path(tournament), params: {
        team_type: "pair_poomsae",
        tournament_category_id: category.id,
        athlete_ids: [athlete_one.id, athlete_two.id]
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "already has a registration decision"
  end

  test "group screen redirects an athlete-role user back to individual" do
    athlete_user = User.create!(name: "Aarohi Shah", email: "athlete-group@example.test", password: "password123", role: :athlete)
    athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = open_tournament
    sign_in_as athlete_user

    get group_tournament_registrations_path(tournament)

    assert_redirected_to individual_tournament_registrations_path(tournament)
    assert_equal "Pair and Team Poomsae aren't available for self-registration.", flash[:alert]
  end

  test "academy owner can submit a pair poomsae entry for exactly 2 team members" do
    owner = User.create!(name: "Owner", email: "owner-pair@example.test", password: "password123", role: :academy_owner)
    academy = owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    athlete_one = owner.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    athlete_two = owner.athletes.create!(academy: academy, first_name: "Ishaani", last_name: "Patel", date_of_birth: Date.new(2013, 3, 1), gender: "female", contact_number: "9876543211")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)
    sign_in_as owner

    assert_difference("Registration.count", 2) do
      post group_tournament_registrations_path(tournament), params: {
        team_type: "pair_poomsae",
        tournament_category_id: category.id,
        athlete_ids: [athlete_one.id, athlete_two.id],
        next: "payment"
      }
    end

    assert_redirected_to payment_tournament_registrations_path(tournament)
    registrations = Registration.last(2)
    assert registrations.all?(&:draft?)
    assert_equal 1, registrations.map(&:submission_batch_id).uniq.size
  end

  test "group entry rejects team members from different academies" do
    owner = User.create!(name: "Owner", email: "owner-mixed@example.test", password: "password123", role: :academy_owner)
    academy_one = owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    academy_two = owner.owned_academies.create!(name: "Deccan Elite", city: "Hyderabad", status: :approved)
    athlete_one = owner.athletes.create!(academy: academy_one, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    athlete_two = owner.athletes.create!(academy: academy_two, first_name: "Ishaani", last_name: "Patel", date_of_birth: Date.new(2013, 3, 1), gender: "female", contact_number: "9876543211")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)
    sign_in_as owner

    assert_no_difference("Registration.count") do
      post group_tournament_registrations_path(tournament), params: {
        team_type: "pair_poomsae",
        tournament_category_id: category.id,
        athlete_ids: [athlete_one.id, athlete_two.id]
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "same academy"
  end

  test "group entry rejects the wrong number of team members" do
    owner = User.create!(name: "Owner", email: "owner-wrongcount@example.test", password: "password123", role: :academy_owner)
    academy = owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    athlete = owner.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)
    sign_in_as owner

    assert_no_difference("Registration.count") do
      post group_tournament_registrations_path(tournament), params: {
        team_type: "pair_poomsae",
        tournament_category_id: category.id,
        athlete_ids: [athlete.id]
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "exactly 2 team members"
  end

  test "submitting the group form with nothing filled in shows the choose-a-category error" do
    owner = User.create!(name: "Owner", email: "owner-empty-group@example.test", password: "password123", role: :academy_owner)
    owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    tournament = open_tournament
    sign_in_as owner

    assert_no_difference("Registration.count") do
      post group_tournament_registrations_path(tournament), params: { team_type: "pair_poomsae", next: "group" }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Choose a Pair or Team Poomsae category."
  end

  test "group screen's teammate dropdown excludes athletes with no academy" do
    owner = User.create!(name: "Owner", email: "owner-no-academy-athlete@example.test", password: "password123", role: :academy_owner)
    academy = owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    on_roster = owner.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    unaffiliated = owner.athletes.create!(first_name: "Riya", last_name: "Solo", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = open_tournament
    sign_in_as owner

    get group_tournament_registrations_path(tournament)

    assert_response :success
    assert_includes response.body, on_roster.full_name
    assert_not_includes response.body, unaffiliated.full_name
  end

  test "add another team submits the current team and returns to a fresh group form" do
    owner = User.create!(name: "Owner", email: "owner-another-team@example.test", password: "password123", role: :academy_owner)
    academy = owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    athlete_one = owner.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    athlete_two = owner.athletes.create!(academy: academy, first_name: "Ishaani", last_name: "Patel", date_of_birth: Date.new(2013, 3, 1), gender: "female", contact_number: "9876543211")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)
    sign_in_as owner

    assert_difference("Registration.count", 2) do
      post group_tournament_registrations_path(tournament), params: {
        team_type: "pair_poomsae",
        tournament_category_id: category.id,
        athlete_ids: [athlete_one.id, athlete_two.id],
        next: "group"
      }
    end

    assert_redirected_to group_tournament_registrations_path(tournament, team_type: "pair_poomsae")
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Already in this registration"
  end

  test "payment screen lists the current draft cart with an itemized total" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 1000)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 1000, fee_currency: "INR")

    get payment_tournament_registrations_path(tournament)

    assert_response :success
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, "1,000"
  end

  test "payment total charges the group fee per teammate for a team entry" do
    owner = User.create!(name: "Owner", email: "owner-group-fee-total@example.test", password: "password123", role: :academy_owner)
    academy = owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    athlete_one = owner.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    athlete_two = owner.athletes.create!(academy: academy, first_name: "Ishaani", last_name: "Patel", date_of_birth: Date.new(2013, 3, 1), gender: "female", contact_number: "9876543211")
    tournament = open_tournament(registration_fee: 1000, group_registration_fee: 3000)
    solo_athlete = owner.athletes.create!(academy: academy, first_name: "Riya", last_name: "Solo", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543212")
    solo_category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    team_category = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)
    batch_id = SecureRandom.uuid
    [athlete_one, athlete_two].each do |athlete|
      tournament.registrations.create!(athlete: athlete, tournament_category: team_category, status: :draft, submission_batch_id: batch_id, fee_amount: 3000, fee_currency: "INR")
    end
    tournament.registrations.create!(athlete: solo_athlete, tournament_category: solo_category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 1000, fee_currency: "INR")
    sign_in_as owner

    get payment_tournament_registrations_path(tournament)

    assert_response :success
    # 3000 x 2 teammates (the Pair Poomsae rate is per-athlete, not flat) + 1000 solo = 7000.
    assert_includes response.body, "7,000"
    assert_not_includes response.body, "4,000"
  end

  test "payment screen never nests the remove-entry form inside the main payment form" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 1000)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 1000, fee_currency: "INR")

    get payment_tournament_registrations_path(tournament)

    assert_response :success
    # Nested <form> elements are invalid HTML and get silently mis-parsed by
    # browsers (the inner form's fields bleed into the outer one) — whichever
    # of the "Remove" form and the payment form comes first in the markup
    # must fully close before the other one opens, not contain it.
    remove_form_open = response.body.index("action=\"#{tournament_registration_path(tournament, registration)}\"")
    payment_form_open = response.body.index("action=\"#{payment_tournament_registrations_path(tournament)}\"")

    assert remove_form_open, "expected a remove form for the draft registration"
    assert payment_form_open, "expected the payment form"

    if payment_form_open < remove_form_open
      payment_form_close = response.body.index("</form>", payment_form_open)
      assert payment_form_close < remove_form_open, "the payment form must close before the remove form opens (no nested <form> tags)"
    else
      remove_form_close = response.body.index("</form>", remove_form_open)
      assert remove_form_close < payment_form_open, "the remove form must close before the payment form opens (no nested <form> tags)"
    end
  end

  test "submit requires a receipt when the cart includes a paid category" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 1000)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 1000, fee_currency: "INR")

    assert_no_difference("Registration.pending.count") do
      post payment_tournament_registrations_path(tournament)
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "receipt"
  end

  test "payment screen shows a cash note box instead of bank/UPI details when the tournament has no payment method, and submit needs no receipt" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 1000, payment_upi_id: nil)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 1000, fee_currency: "INR")

    get payment_tournament_registrations_path(tournament)

    assert_response :success
    assert_includes response.body, "Cash/UPI payment done to"
    assert_not_includes response.body, "Secure payment details"

    assert_difference("Registration.pending.count", 1) do
      post payment_tournament_registrations_path(tournament), params: { payment_note: "Paid cash to Coach Meera" }
    end

    assert_redirected_to tournament_registrations_path(tournament)
    assert_equal "Paid cash to Coach Meera", Registration.last.payment_note
  end

  test "payment screen does not offer a cash option when the tournament has payment details and does not allow cash" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 1000)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 1000, fee_currency: "INR")

    get payment_tournament_registrations_path(tournament)

    assert_response :success
    assert_includes response.body, "Secure payment details"
    assert_not_includes response.body, "Cash/UPI payment done to"

    assert_no_difference("Registration.pending.count") do
      post payment_tournament_registrations_path(tournament)
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "receipt"
  end

  test "payment screen offers a cash checkbox alongside bank/UPI details when the tournament allows cash payment, and checking it skips the receipt" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 1000, allow_cash_payment: true)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 1000, fee_currency: "INR")

    get payment_tournament_registrations_path(tournament)

    assert_response :success
    assert_includes response.body, "Secure payment details"
    assert_includes response.body, "Cash/UPI payment done to"

    assert_difference("Registration.pending.count", 1) do
      post payment_tournament_registrations_path(tournament), params: { paid_by_cash: "1", payment_note: "Paid cash to Coach Meera" }
    end

    assert_redirected_to tournament_registrations_path(tournament)
    registration = Registration.last
    assert registration.paid_by_cash?
    assert_equal "Paid cash to Coach Meera", registration.payment_note
    assert_not registration.payment_receipt.attached?
  end

  test "payment screen still requires a receipt when cash payment is allowed but the checkbox is left unchecked" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 1000, allow_cash_payment: true)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 1000, fee_currency: "INR")

    assert_no_difference("Registration.pending.count") do
      post payment_tournament_registrations_path(tournament)
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "receipt"
  end

  test "academy owner can build an individual entry plus a pair poomsae team in one cart and submit both together" do
    owner = User.create!(name: "Owner", email: "owner-combined-submit@example.test", password: "password123", role: :academy_owner)
    academy = owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    solo_athlete = owner.athletes.create!(academy: academy, first_name: "Ishaan", last_name: "Deshmukh", date_of_birth: Date.new(2012, 6, 1), gender: "male", contact_number: "9876543210")
    team_athlete_one = owner.athletes.create!(academy: academy, first_name: "Kabir", last_name: "Patil", date_of_birth: Date.new(2012, 1, 1), gender: "male", contact_number: "9876543211")
    team_athlete_two = owner.athletes.create!(academy: academy, first_name: "Rehan", last_name: "Shaikh", date_of_birth: Date.new(2013, 1, 1), gender: "male", contact_number: "9876543212")
    tournament = open_tournament(registration_fee: 800, group_registration_fee: 1500)
    solo_category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 15, weight_min: 30, weight_max: 45)
    team_category = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)
    sign_in_as owner

    assert_difference("Registration.count", 1) do
      post individual_tournament_registrations_path(tournament), params: {
        athlete_id: solo_athlete.id, tournament_category_ids: [solo_category.id], next: "group"
      }
    end
    assert_redirected_to group_tournament_registrations_path(tournament)

    assert_difference("Registration.count", 2) do
      post group_tournament_registrations_path(tournament), params: {
        team_type: "pair_poomsae", tournament_category_id: team_category.id,
        athlete_ids: [team_athlete_one.id, team_athlete_two.id], next: "payment"
      }
    end
    assert_redirected_to payment_tournament_registrations_path(tournament)

    assert_equal 3, tournament.registrations.draft.count

    assert_difference("Registration.pending.count", 3) do
      post payment_tournament_registrations_path(tournament), params: { payment_receipt: payment_receipt_upload }
    end

    assert_redirected_to tournament_registrations_path(tournament)
    registrations = tournament.registrations.reload
    assert registrations.all?(&:pending?)
    assert registrations.all? { |registration| registration.payment_receipt.attached? }
    assert_equal [solo_athlete.id, team_athlete_one.id, team_athlete_two.id].sort, registrations.map(&:athlete_id).sort
  end

  test "submit finalizes every draft registration in the cart and attaches one shared receipt" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 1000)
    category_one = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    category_two = tournament.tournament_categories.find_or_create_by!(event_type: "individual_poomsae", gender: "female", age_min: 12, age_max: 14)
    batch_id = SecureRandom.uuid
    tournament.registrations.create!(athlete: athlete, tournament_category: category_one, status: :draft, submission_batch_id: batch_id, fee_amount: 1000, fee_currency: "INR")
    tournament.registrations.create!(athlete: athlete, tournament_category: category_two, status: :draft, submission_batch_id: batch_id, fee_amount: 800, fee_currency: "INR")

    assert_difference("Registration.pending.count", 2) do
      post payment_tournament_registrations_path(tournament), params: { payment_receipt: payment_receipt_upload }
    end

    assert_redirected_to tournament_registrations_path(tournament)
    Registration.where(athlete: athlete).each do |registration|
      assert_predicate registration, :pending?
      assert_predicate registration.payment_receipt, :attached?
    end
  end

  test "submit is a no-op with a friendly redirect when the cart is empty" do
    tournament = open_tournament

    post payment_tournament_registrations_path(tournament)

    assert_redirected_to individual_tournament_registrations_path(tournament)
    assert_equal "Add at least one athlete or entry before paying.", flash[:alert]
  end

  test "submit is blocked once registration has closed even with a staged draft" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9876543210")
    tournament = open_tournament(registration_fee: 0)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37, registration_fee: 0)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 0, fee_currency: "INR")
    tournament.update_column(:registration_closes_at, 1.hour.ago)

    assert_no_difference("Registration.pending.count") do
      post payment_tournament_registrations_path(tournament)
    end

    assert_redirected_to tournament_path(tournament)
    assert_equal "Registration is not open for this tournament.", flash[:alert]
  end

  test "destroy removes a single draft registration" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 0, fee_currency: "INR")

    assert_difference("Registration.count", -1) do
      delete tournament_registration_path(tournament, registration)
    end
  end

  test "destroy removes every registration sharing a group entry's batch id" do
    owner = User.create!(name: "Owner", email: "owner-destroy@example.test", password: "password123", role: :academy_owner)
    academy = owner.owned_academies.create!(name: "Pune Champions", city: "Pune", status: :approved)
    athlete_one = owner.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    athlete_two = owner.athletes.create!(academy: academy, first_name: "Ishaani", last_name: "Patel", date_of_birth: Date.new(2013, 3, 1), gender: "female")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)
    batch_id = SecureRandom.uuid
    registration_one = tournament.registrations.create!(athlete: athlete_one, tournament_category: category, status: :draft, submission_batch_id: batch_id, fee_amount: 0, fee_currency: "INR")
    tournament.registrations.create!(athlete: athlete_two, tournament_category: category, status: :draft, submission_batch_id: batch_id, fee_amount: 0, fee_currency: "INR")
    sign_in_as owner

    assert_difference("Registration.count", -2) do
      delete tournament_registration_path(tournament, registration_one)
    end
  end

  test "destroy cannot remove another user's registration" do
    other_parent = User.create!(name: "Other Parent", email: "other-parent@example.test", password: "password123", role: :parent)
    athlete = other_parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 0, fee_currency: "INR")

    delete tournament_registration_path(tournament, registration)

    assert_response :not_found
  end

  test "index never shows a draft registration" do
    athlete = @parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = open_tournament
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    tournament.registrations.create!(athlete: athlete, tournament_category: category, status: :draft, submission_batch_id: SecureRandom.uuid, fee_amount: 0, fee_currency: "INR")

    get tournament_registrations_path(tournament)

    assert_not_includes response.body, "Aarohi Shah"
  end
end
