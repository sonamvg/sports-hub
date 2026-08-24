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
end
