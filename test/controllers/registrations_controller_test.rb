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

  test "new redirects an athlete-role user straight to the individual screen" do
    athlete_user = User.create!(name: "Aarohi Shah", email: "athlete-new@example.test", password: "password123", role: :athlete)
    athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = open_tournament
    sign_in_as athlete_user

    get new_tournament_registration_path(tournament)

    assert_redirected_to individual_tournament_registrations_path(tournament)
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
