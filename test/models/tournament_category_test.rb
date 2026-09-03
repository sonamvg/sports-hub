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
end
