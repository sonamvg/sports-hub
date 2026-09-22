require "test_helper"

class TournamentOrganizerInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "invite-organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(name: "Pune Invitational", organizer: @organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
  end

  test "a plain collaborator cannot invite further organizers" do
    collaborator = User.create!(name: "Collaborator", email: "invite-collaborator@example.test", password: "password123", role: :organizer)
    @tournament.tournament_organizers.create!(user: collaborator, added_by: @organizer, role: :collaborator)
    sign_in_as collaborator

    assert_no_difference("TournamentOrganizerInvitation.count") do
      post tournament_tournament_organizer_invitations_path(@tournament), params: { tournament_organizer_invitation: { email: "new-organizer@example.test" } }
    end

    assert_response :not_found
  end

  test "the tournament owner can invite further organizers" do
    sign_in_as @organizer

    assert_difference("TournamentOrganizerInvitation.count", 1) do
      post tournament_tournament_organizer_invitations_path(@tournament), params: { tournament_organizer_invitation: { email: "new-organizer@example.test" } }
    end

    assert_redirected_to edit_tournament_path(@tournament)
  end
end
