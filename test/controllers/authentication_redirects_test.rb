require "test_helper"

class AuthenticationRedirectsTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(
      name: "Pune Invitational",
      organizer: @organizer,
      status: :registration_open,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
  end

  test "protected pages redirect to login without passive sign in alert" do
    protected_paths = [
      new_tournament_path,
      new_athlete_path,
      new_academy_path,
      new_tournament_registration_path(@tournament),
      organizer_registrations_path
    ]

    protected_paths.each do |path|
      get path

      assert_redirected_to login_path(return_to: path)
      assert_nil flash[:alert], "expected no passive alert for #{path}"
    end
  end
end
