require "test_helper"

class TournamentOrganizerInvitationTest < ActiveSupport::TestCase
  test "validates email format and existing verified organizer emails" do
    organizer = User.create!(name: "Organizer", email: "invite-owner@example.test", password: "password123", role: :organizer)
    existing = User.create!(name: "Existing Organizer", email: "existing-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Invite Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))

    invalid = tournament.tournament_organizer_invitations.build(email: "bad-email", invited_by: organizer)
    assert_not invalid.valid?
    assert_includes invalid.errors[:email], "is invalid"

    duplicate = tournament.tournament_organizer_invitations.build(email: existing.email, invited_by: organizer)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "already belongs to a verified organiser"
  end
end
