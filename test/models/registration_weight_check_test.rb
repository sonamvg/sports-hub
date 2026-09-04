require "test_helper"

class RegistrationWeightCheckTest < ActiveSupport::TestCase
  test "weight checks are locked once the draw has been generated" do
    organizer = User.create!(name: "Organizer", email: "lock-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Lock Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 18, weight_max: 80)

    parent = User.create!(name: "Parent", email: "lock-parent@example.test", password: "password123", role: :parent)
    athlete = parent.athletes.create!(first_name: "Lock", last_name: "Athlete", date_of_birth: Date.new(2005, 1, 1), gender: "male")
    registration = Registration.create!(
      tournament: tournament,
      athlete: athlete,
      tournament_category: category,
      status: :approved,
      payment_receipt: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/payment-receipt.png"), "image/png")
    )

    category.update!(draw_generated_at: Time.current)

    weight_check = registration.registration_weight_checks.build(checked_by: organizer, weight: 75)

    assert_not weight_check.valid?
    assert_includes weight_check.errors[:base], "Weight check is locked because the draw has already been set"
  end
end
