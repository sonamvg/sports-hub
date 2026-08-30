require "test_helper"

class TournamentDrawMatchTest < ActiveSupport::TestCase
  setup do
    @organizer = User.create!(name: "Organizer", email: "match-organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(
      name: "Match Result Open",
      organizer: @organizer,
      status: :registration_closed,
      registration_opens_at: 10.days.ago,
      registration_closes_at: 1.day.ago,
      start_date: 2.days.from_now.to_date,
      end_date: 3.days.from_now.to_date
    )
    @category = @tournament.tournament_categories.create!(event_type: "kyorugi", gender: "male", age_min: 15, age_max: 17, weight_min: 51, weight_max: 55)
    @first_registration = create_registration("Aarav", "Rane")
    @second_registration = create_registration("Dev", "Shetty")
    @third_registration = create_registration("Kabir", "Kapoor")
    @fourth_registration = create_registration("Neil", "Bhat")
    @draw = @tournament.tournament_draws.create!(
      tournament_category: @category,
      generated_by: @organizer,
      bracket_size: 4,
      round_count: 2,
      entry_count: 4,
      generated_at: Time.current
    )
  end

  test "records scores and advances winner to next round" do
    first_match = @draw.tournament_draw_matches.create!(
      round_number: 1,
      position: 1,
      red_registration: @first_registration,
      blue_registration: @second_registration,
      red_head_guard_color: "red",
      blue_head_guard_color: "blue"
    )
    @draw.tournament_draw_matches.create!(
      round_number: 2,
      position: 1,
      red_source_match_position: 1,
      blue_source_match_position: 2,
      red_head_guard_color: "blue",
      blue_head_guard_color: "red"
    )

    assert first_match.record_result!(
      actor: @organizer,
      attributes: {
        red_round_1_points: 8,
        blue_round_1_points: 4,
        red_round_2_points: 7,
        blue_round_2_points: 6,
        red_round_3_points: 2,
        blue_round_3_points: 5,
        red_head_guard_color: "red",
        blue_head_guard_color: "blue"
      }
    )

    assert_equal @first_registration, first_match.reload.winner_registration
    assert_equal @first_registration, @draw.tournament_draw_matches.find_by(round_number: 2, position: 1).red_registration
  end

  test "winner is based on sets won not total points" do
    match = @draw.tournament_draw_matches.create!(
      round_number: 1,
      position: 1,
      red_registration: @first_registration,
      blue_registration: @second_registration,
      red_head_guard_color: "red",
      blue_head_guard_color: "blue"
    )

    assert match.record_result!(
      actor: @organizer,
      attributes: {
        red_round_1_points: 14,
        blue_round_1_points: 5,
        red_round_2_points: 2,
        blue_round_2_points: 3,
        red_round_3_points: 2,
        blue_round_3_points: 3,
        red_head_guard_color: "red",
        blue_head_guard_color: "blue"
      }
    )

    assert_equal 1, match.red_round_wins
    assert_equal 2, match.blue_round_wins
    assert_equal @second_registration, match.reload.winner_registration
  end

  test "does not freeze when round points are tied" do
    match = @draw.tournament_draw_matches.create!(
      round_number: 1,
      position: 1,
      red_registration: @first_registration,
      blue_registration: @second_registration,
      red_head_guard_color: "red",
      blue_head_guard_color: "blue"
    )

    assert_not match.record_result!(
      actor: @organizer,
      attributes: {
        red_round_1_points: 5,
        blue_round_1_points: 5,
        red_round_2_points: 6,
        blue_round_2_points: 4,
        red_round_3_points: 3,
        blue_round_3_points: 5,
        red_head_guard_color: "red",
        blue_head_guard_color: "blue"
      }
    )
    assert_includes match.errors.full_messages, "Resolve tied round scores before freezing result"
  end

  test "ready to freeze only when no completed rounds are tied" do
    match = @draw.tournament_draw_matches.create!(
      round_number: 1,
      position: 1,
      red_registration: @first_registration,
      blue_registration: @second_registration,
      red_head_guard_color: "red",
      blue_head_guard_color: "blue"
    )

    match.assign_attributes(
      red_round_1_points: 5,
      blue_round_1_points: 5,
      red_round_2_points: 6,
      blue_round_2_points: 4,
      red_round_3_points: 3,
      blue_round_3_points: 5
    )

    assert_not_predicate match, :ready_to_freeze?

    match.red_round_1_points = 4

    assert_predicate match, :ready_to_freeze?
  end

  test "does not allow a frozen result to be changed" do
    match = @draw.tournament_draw_matches.create!(
      round_number: 1,
      position: 1,
      red_registration: @first_registration,
      blue_registration: @second_registration,
      red_head_guard_color: "blue",
      blue_head_guard_color: "red"
    )

    assert match.record_result!(actor: @organizer, attributes: match_score(red_wins: true))

    assert_not match.record_result!(actor: @organizer, attributes: match_score(red_wins: false))
    assert_includes match.errors.full_messages, "Result is frozen and cannot be edited"
    assert_equal @first_registration, match.reload.winner_registration
    assert_equal 6, match.red_round_1_points
    assert_equal 2, match.blue_round_1_points
  end

  test "does not treat empty round scores as tied" do
    match = @draw.tournament_draw_matches.create!(
      round_number: 1,
      position: 1,
      red_registration: @first_registration,
      blue_registration: @second_registration,
      red_head_guard_color: "blue",
      blue_head_guard_color: "red"
    )

    assert_not match.round_points_tied?(1)

    match.red_round_1_points = 5

    assert_not match.round_points_tied?(1)

    match.blue_round_1_points = 5

    assert match.round_points_tied?(1)
  end

  test "advances bye winner" do
    bye_match = @draw.tournament_draw_matches.create!(
      round_number: 1,
      position: 2,
      red_registration: @third_registration,
      bye: true,
      red_head_guard_color: "blue",
      blue_head_guard_color: "red"
    )
    @draw.tournament_draw_matches.create!(
      round_number: 2,
      position: 1,
      red_source_match_position: 1,
      blue_source_match_position: 2,
      red_head_guard_color: "red",
      blue_head_guard_color: "blue"
    )

    bye_match.assign_bye_winner!

    assert_equal @third_registration, bye_match.reload.winner_registration
    assert_equal @third_registration, @draw.tournament_draw_matches.find_by(round_number: 2, position: 1).blue_registration
  end

  test "labels semifinal loser bronze and final athletes gold and silver" do
    first_semifinal = @draw.tournament_draw_matches.create!(
      round_number: 1,
      position: 1,
      red_registration: @first_registration,
      blue_registration: @second_registration,
      red_head_guard_color: "blue",
      blue_head_guard_color: "red"
    )
    second_semifinal = @draw.tournament_draw_matches.create!(
      round_number: 1,
      position: 2,
      red_registration: @third_registration,
      blue_registration: @fourth_registration,
      red_head_guard_color: "blue",
      blue_head_guard_color: "red"
    )
    final = @draw.tournament_draw_matches.create!(
      round_number: 2,
      position: 1,
      red_source_match_position: 1,
      blue_source_match_position: 2,
      red_head_guard_color: "blue",
      blue_head_guard_color: "red"
    )

    assert first_semifinal.record_result!(actor: @organizer, attributes: match_score(red_wins: true))
    assert second_semifinal.record_result!(actor: @organizer, attributes: match_score(red_wins: true))
    assert final.reload.record_result!(actor: @organizer, attributes: match_score(red_wins: true))

    assert_equal "Advanced", first_semifinal.result_label_for(@first_registration)
    assert_equal "Bronze", first_semifinal.result_label_for(@second_registration)
    assert_equal "Gold", final.reload.result_label_for(@first_registration)
    assert_equal "Silver", final.result_label_for(@third_registration)
  end

  private

  def match_score(red_wins:)
    if red_wins
      {
        red_round_1_points: 6,
        blue_round_1_points: 2,
        red_round_2_points: 3,
        blue_round_2_points: 4,
        red_round_3_points: 5,
        blue_round_3_points: 1
      }
    else
      {
        red_round_1_points: 2,
        blue_round_1_points: 6,
        red_round_2_points: 4,
        blue_round_2_points: 3,
        red_round_3_points: 1,
        blue_round_3_points: 5
      }
    end
  end

  def create_registration(first_name, last_name)
    user = User.create!(
      name: "#{first_name} #{last_name}",
      email: "#{first_name.downcase}-#{last_name.downcase}-match@example.test",
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
