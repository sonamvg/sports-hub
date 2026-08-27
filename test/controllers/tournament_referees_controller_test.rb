require "test_helper"

class TournamentRefereesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "referee-organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(
      name: "Referee Open",
      organizer: @organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
    sign_in_as @organizer
  end

  test "index shows referee details to tournament manager" do
    @tournament.tournament_referees.create!(
      name: "Meera Rao",
      phone: "9876543210",
      email: "meera@example.test",
      qualification: "National referee"
    )

    get tournament_tournament_referees_path(@tournament)

    assert_response :success
    assert_includes response.body, "Meera Rao"
    assert_includes response.body, "9876543210"
    assert_includes response.body, "National referee"
  end

  test "creates referee with photo" do
    assert_difference("@tournament.tournament_referees.count", 1) do
      post tournament_tournament_referees_path(@tournament), params: {
        tournament_referee: {
          name: "Meera Rao",
          phone: "9876543210",
          email: "meera@example.test",
          role: "Center referee",
          qualification: "National referee",
          certification_id: "NR-102",
          affiliation: "Pune Taekwondo Association",
          notes: "Available for court one",
          photo: tournament_image_upload
        }
      }
    end

    referee = @tournament.tournament_referees.order(:created_at).last
    assert_redirected_to tournament_tournament_referees_path(@tournament)
    assert_equal "Meera Rao", referee.name
    assert_equal "Center referee", referee.role
    assert_predicate referee.photo, :attached?
  end

  test "renders errors when referee is invalid" do
    assert_no_difference("@tournament.tournament_referees.count") do
      post tournament_tournament_referees_path(@tournament), params: {
        tournament_referee: {
          name: "",
          email: "bad-email"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Name can&#39;t be blank"
    assert_includes response.body, "Email is invalid"
  end

  test "updates referee" do
    referee = @tournament.tournament_referees.create!(name: "Meera Rao", role: "Judge")

    patch tournament_tournament_referee_path(@tournament, referee), params: {
      tournament_referee: {
        name: "Meera Rao",
        role: "Center referee",
        qualification: "State referee"
      }
    }

    assert_redirected_to tournament_tournament_referee_path(@tournament, referee)
    assert_equal "Center referee", referee.reload.role
    assert_equal "State referee", referee.qualification
  end

  test "destroys referee" do
    referee = @tournament.tournament_referees.create!(name: "Meera Rao")

    assert_difference("@tournament.tournament_referees.count", -1) do
      delete tournament_tournament_referee_path(@tournament, referee)
    end

    assert_redirected_to tournament_tournament_referees_path(@tournament)
  end

  test "non manager cannot access referee contact details" do
    referee = @tournament.tournament_referees.create!(name: "Meera Rao", phone: "9876543210")
    other = User.create!(name: "Other User", email: "referee-other@example.test", password: "password123", role: :organizer)
    sign_in_as other

    get tournament_tournament_referee_path(@tournament, referee)

    assert_response :not_found
  end
end
