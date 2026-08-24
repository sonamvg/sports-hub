require "test_helper"

class OrganizerRegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "organizer sees only registrations for owned tournaments" do
    organizer = User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :organizer)
    other_organizer = User.create!(name: "Other Organizer", email: "other-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "athlete-user@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")

    owned_tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    owned_category = owned_tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    owned_registration = owned_tournament.registrations.create!(athlete: athlete, tournament_category: owned_category)

    other_tournament = Tournament.create!(name: "Other Open", organizer: other_organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    other_category = other_tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    other_tournament.registrations.create!(athlete: athlete, tournament_category: other_category)
    sign_in_as organizer

    get organizer_registrations_path

    assert_response :success
    assert_includes response.body, owned_registration.tournament.name
    assert_not_includes response.body, other_tournament.name
  end
end
