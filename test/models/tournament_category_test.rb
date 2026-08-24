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
end
