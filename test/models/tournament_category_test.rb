require "test_helper"

class TournamentCategoryTest < ActiveSupport::TestCase
  test "maximum age cannot be below minimum age" do
    category = TournamentCategory.new(event_type: "kyorugi", age_min: 14, age_max: 12)

    assert_not category.valid?
    assert_includes category.errors[:age_max], "cannot be below minimum age"
  end

  test "maximum weight cannot be below minimum weight" do
    category = TournamentCategory.new(event_type: "kyorugi", weight_min: 44, weight_max: 41)

    assert_not category.valid?
    assert_includes category.errors[:weight_max], "cannot be below minimum weight"
  end

  test "name is generated from structured fields" do
    category = TournamentCategory.new(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    category.valid?

    assert_equal "Kyorugi Female Age 12-14 U41", category.name
  end

  test "duplicate structured categories are blocked per tournament" do
    organizer = User.create!(name: "Organizer", email: "organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Pune Invitational", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    duplicate = tournament.tournament_categories.build(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:category_key], "already exists for this tournament"
  end

  test "effective_registration_fee uses the group fee for pair and team poomsae categories" do
    organizer = User.create!(name: "Organizer", email: "fee-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Fee Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6), registration_fee: 500, group_registration_fee: 1500)

    kyorugi = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 13, age_max: 15, weight_min: 33, weight_max: 37)
    individual_poomsae = tournament.tournament_categories.find_or_create_by!(event_type: "individual_poomsae", gender: "male", age_min: 12, age_max: 14)
    pair_poomsae = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)
    team_poomsae = tournament.tournament_categories.find_or_create_by!(event_type: "team_poomsae", gender: nil, age_min: 12, age_max: 17)

    assert_equal 500, kyorugi.effective_registration_fee
    assert_equal 500, individual_poomsae.effective_registration_fee
    assert_equal 1500, pair_poomsae.effective_registration_fee
    assert_equal 1500, team_poomsae.effective_registration_fee
  end

  test "free? checks the fee relevant to the category's event type" do
    organizer = User.create!(name: "Organizer", email: "free-check-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Free Check Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6), registration_fee: 0, group_registration_fee: 1500)

    kyorugi = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 13, age_max: 15, weight_min: 33, weight_max: 37)
    team_poomsae = tournament.tournament_categories.find_or_create_by!(event_type: "team_poomsae", gender: nil, age_min: 12, age_max: 17)

    assert_predicate kyorugi, :free?
    assert_not team_poomsae.free?
  end

  test "free? treats a blank group fee as free, matching Tournament#free?'s documented semantics" do
    organizer = User.create!(name: "Organizer", email: "blank-group-fee-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Blank Group Fee Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6), registration_fee: 500, group_registration_fee: nil)

    kyorugi = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 13, age_max: 15, weight_min: 33, weight_max: 37)
    pair_poomsae = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)

    assert_not kyorugi.free?, "an unset individual fee should still be treated as undecided, not free"
    assert_predicate pair_poomsae, :free?
  end

  test "reset_draw! clears matches and re-opens weight checks, but not once a match is completed" do
    organizer = User.create!(name: "Organizer", email: "reset-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Reset Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "male", age_min: 18)
    3.times { |i| create_weight_verified_registration(tournament: tournament, category: category, email: "reset-#{i}@example.test") }

    BracketGenerator.new(category).call
    category.reload
    assert category.draw_generated?
    assert_not category.draw_locked?

    category.reset_draw!
    category.reload
    assert_not category.draw_generated?
    assert_equal 0, category.matches.count

    BracketGenerator.new(category).call
    category.reload
    real_match = category.matches.find(&:ready_for_result?)
    real_match.record_result!(winner_registration_id: real_match.registration_one_id, decision: :points, score_data: {})

    assert category.reload.draw_locked?
    assert_raises(RuntimeError) { category.reset_draw! }
  end

  test "suggested_individual_categories matches gender and age, splits by event type, and recommends the closest kyorugi bracket" do
    organizer = User.create!(name: "Organizer", email: "suggest-organizer@example.test", password: "password123", role: :organizer)
    parent = User.create!(name: "Parent", email: "suggest-parent@example.test", password: "password123", role: :parent)
    # Age 13 as of the tournament start date, safely inside the custom 12-14
    # band below and clear of the auto-generated default divisions' 9-12/13-15
    # boundary, so this test isn't tripped up by Tournament's default categories.
    athlete = parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2013, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Suggest Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))

    # Weight bounds deliberately don't line up with any auto-generated default
    # bracket's boundaries (Tournament#assign_default_categories always runs
    # on create), so there's no risk of a tie with a same-age-band default.
    close_bracket = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 34.5, weight_max: 34.9)
    far_bracket = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 80, weight_max: 85)
    poomsae = tournament.tournament_categories.find_or_create_by!(event_type: "individual_poomsae", gender: "female", age_min: 12, age_max: 14)
    wrong_gender = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    wrong_age = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 15, age_max: 17, weight_min: 33, weight_max: 37)
    group_category = tournament.tournament_categories.find_or_create_by!(event_type: "pair_poomsae", gender: nil, age_min: 12, age_max: 17)

    categories = tournament.tournament_categories.where.not(event_type: TournamentCategory::GROUP_EVENT_TYPES)
    result = TournamentCategory.suggested_individual_categories(categories, athlete: athlete, as_of: tournament.start_date, weight: 34.2)

    assert_includes result[:kyorugi], close_bracket
    assert_includes result[:kyorugi], far_bracket
    assert_includes result[:individual_poomsae], poomsae
    assert_equal close_bracket, result[:recommended]
    assert_not_includes result[:kyorugi] + result[:individual_poomsae], wrong_gender
    assert_not_includes result[:kyorugi] + result[:individual_poomsae], wrong_age
    assert_not_includes result[:kyorugi] + result[:individual_poomsae], group_category
  end

  test "suggested_individual_categories recommends nothing when weight is blank" do
    organizer = User.create!(name: "Organizer", email: "suggest-noweight-organizer@example.test", password: "password123", role: :organizer)
    parent = User.create!(name: "Parent", email: "suggest-noweight-parent@example.test", password: "password123", role: :parent)
    athlete = parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2013, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Suggest No Weight Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 20, weight_max: 25)
    tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 34.5, weight_max: 36.5)

    # With no entered weight and no profile weight to fall back on, there's
    # no basis for a "closest" guess — every matching bracket should be
    # listed with none singled out, rather than an arbitrary first pick.
    categories = tournament.tournament_categories.where.not(event_type: TournamentCategory::GROUP_EVENT_TYPES).order(:weight_min)
    result = TournamentCategory.suggested_individual_categories(categories, athlete: athlete, as_of: tournament.start_date, weight: nil)

    assert_nil result[:recommended]
  end
end
