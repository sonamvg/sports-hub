require "test_helper"

class TournamentDrawMatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Draw Organizer", email: "draw-match-controller@example.test", password: "password123", role: :organizer)
    sign_in_as @organizer
    @tournament = Tournament.create!(
      name: "Controller Draw Open",
      organizer: @organizer,
      status: :draw_scheduling,
      registration_opens_at: 10.days.ago,
      registration_closes_at: 1.day.ago,
      start_date: 2.days.from_now.to_date,
      end_date: 3.days.from_now.to_date
    )
    @category = @tournament.tournament_categories.create!(event_type: "kyorugi", gender: "male", age_min: 15, age_max: 17, weight_min: 51, weight_max: 55)
    @first_registration = create_registration("Aarav", "Rane")
    @second_registration = create_registration("Dev", "Shetty")
    @draw = @tournament.tournament_draws.create!(
      tournament_category: @category,
      generated_by: @organizer,
      bracket_size: 4,
      round_count: 2,
      entry_count: 2,
      generated_at: Time.current
    )
    @match = @draw.tournament_draw_matches.create!(
      round_number: 1,
      position: 1,
      red_registration: @first_registration,
      blue_registration: @second_registration,
      red_head_guard_color: "red",
      blue_head_guard_color: "blue"
    )
    @final = @draw.tournament_draw_matches.create!(
      round_number: 2,
      position: 1,
      red_source_match_position: 1,
      blue_source_match_position: 2,
      red_head_guard_color: "blue",
      blue_head_guard_color: "red"
    )
  end

  test "organizer saves draft scores without advancing winner" do
    patch result_tournament_draw_match_path(@match), params: {
      tournament_draw_match: {
        red_round_1_points: 10,
        blue_round_1_points: 8
      }
    }

    assert_redirected_to draw_tournament_path(@tournament)
    assert_equal "Score saved.", flash[:notice]
    assert_nil @match.reload.winner_registration
    assert_equal 10, @match.red_round_1_points
    assert_equal 8, @match.blue_round_1_points
    assert_nil @final.reload.red_registration
  end

  test "organizer freezes match result and advances winner" do
    patch result_tournament_draw_match_path(@match), params: {
      score_action: "Freeze result",
      tournament_draw_match: {
        red_round_1_points: 10,
        blue_round_1_points: 8,
        red_round_2_points: 6,
        blue_round_2_points: 9,
        red_round_3_points: 7,
        blue_round_3_points: 5
      }
    }

    assert_redirected_to draw_tournament_path(@tournament)
    assert_equal "Match result frozen.", flash[:notice]
    assert_equal @first_registration, @match.reload.winner_registration
    assert_equal "red", @match.red_head_guard_color
    assert_equal "blue", @match.blue_head_guard_color
    assert_equal @first_registration, @final.reload.red_registration
  end

  test "frozen result is reflected on athlete and academy pages" do
    academy_owner = User.create!(name: "Academy Owner", email: "draw-propagation-owner@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Propagation Academy", city: "Pune", status: :approved, owner: academy_owner)
    @first_registration.athlete.update!(academy: academy, external_academy_name: nil)

    patch result_tournament_draw_match_path(@match), params: {
      score_action: "Freeze result",
      tournament_draw_match: {
        red_round_1_points: 10,
        blue_round_1_points: 8,
        red_round_2_points: 6,
        blue_round_2_points: 9,
        red_round_3_points: 7,
        blue_round_3_points: 5
      }
    }

    assert_redirected_to draw_tournament_path(@tournament)
    assert_equal @first_registration, @match.reload.winner_registration

    delete logout_path
    sign_in_as @first_registration.athlete.user
    get athlete_path(@first_registration.athlete)

    assert_response :success
    assert_includes response.body, "Waiting for opponent"
    assert_includes response.body, "You have advanced to"
    assert_includes response.body, "23 - 22"
    assert_includes response.body, "Blue"

    delete logout_path
    sign_in_as academy_owner
    get academy_path(academy)

    assert_response :success
    assert_includes response.body, "Athlete tournament status"
    assert_includes response.body, @first_registration.athlete.full_name
    assert_includes response.body, "Waiting for opponent"
    assert_includes response.body, "You have advanced to"
    assert_includes response.body, "23 - 22"
    assert_includes response.body, "Blue"
  end

  test "organizer cannot freeze when round points are tied" do
    patch result_tournament_draw_match_path(@match), params: {
      score_action: "Freeze result",
      tournament_draw_match: {
        red_round_1_points: 10,
        blue_round_1_points: 10,
        red_round_2_points: 6,
        blue_round_2_points: 9,
        red_round_3_points: 4,
        blue_round_3_points: 3
      }
    }

    assert_redirected_to draw_tournament_path(@tournament)
    assert_equal "Resolve tied round scores before freezing result", flash[:alert]
    assert_nil @match.reload.winner_registration
    assert_nil @final.reload.red_registration
  end

  test "organizer freezes when every completed round has a point winner" do
    patch result_tournament_draw_match_path(@match), params: {
      score_action: "Freeze result",
      tournament_draw_match: {
        red_round_1_points: 9,
        blue_round_1_points: 10,
        red_round_2_points: 6,
        blue_round_2_points: 9,
        red_round_3_points: 4,
        blue_round_3_points: 3
      }
    }

    assert_redirected_to draw_tournament_path(@tournament)
    assert_equal "Match result frozen.", flash[:notice]
    assert_equal @second_registration, @match.reload.winner_registration
    assert_equal @second_registration, @final.reload.red_registration
  end

  test "organizer cannot edit a frozen result" do
    assert @match.record_result!(
      actor: @organizer,
      attributes: {
        red_round_1_points: 10,
        blue_round_1_points: 8,
        red_round_2_points: 6,
        blue_round_2_points: 9,
        red_round_3_points: 7,
        blue_round_3_points: 5
      }
    )

    patch result_tournament_draw_match_path(@match), params: {
      score_action: "Freeze result",
      tournament_draw_match: {
        red_round_1_points: 1,
        blue_round_1_points: 9,
        red_round_2_points: 1,
        blue_round_2_points: 9,
        red_round_3_points: 1,
        blue_round_3_points: 9
      }
    }

    assert_redirected_to draw_tournament_path(@tournament)
    assert_equal "Result is frozen and cannot be edited", flash[:alert]
    assert_equal @first_registration, @match.reload.winner_registration
    assert_equal 10, @match.red_round_1_points
    assert_equal 8, @match.blue_round_1_points
  end

  private

  def create_registration(first_name, last_name)
    user = User.create!(
      name: "#{first_name} #{last_name}",
      email: "#{first_name.downcase}-#{last_name.downcase}-controller@example.test",
      password: "password123",
      role: :athlete
    )
    athlete = user.athletes.create!(
      first_name: first_name,
      last_name: last_name,
      date_of_birth: Date.new(2009, 8, 14),
      gender: "male",
      external_academy_name: "#{first_name} Academy"
    )
    @tournament.registrations.create!(
      athlete: athlete,
      tournament_category: @category,
      status: :weight_verified,
      payment_receipt: payment_receipt_upload
    )
  end
end
