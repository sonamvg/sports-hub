require "test_helper"

class MatchTest < ActiveSupport::TestCase
  setup do
    @organizer = User.create!(name: "Organizer", email: "match-organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(name: "Match Open", organizer: @organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    @category = @tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 18)
    @registrations = 4.times.map { |i| create_weight_verified_registration(tournament: @tournament, category: @category, email: "match-#{i}@example.test") }
    BracketGenerator.new(@category).call
    @category.reload
  end

  test "recording a semifinal result advances the winner and awards bronze to the loser" do
    semifinal = @category.matches.find_by(round_number: 1, slot_position: 1)
    winner_id = semifinal.registration_one_id
    loser_id = semifinal.registration_two_id

    semifinal.record_result!(winner_registration_id: winner_id, decision: :points, score_data: { "rounds_won" => { "one" => 2, "two" => 0 } })
    semifinal.reload

    assert semifinal.completed?
    assert_equal "bronze", semifinal.medal
    assert_equal winner_id, semifinal.winner_registration_id
    assert_equal loser_id, semifinal.loser_registration_id

    final = semifinal.next_match
    assert_equal winner_id, [ final.registration_one_id, final.registration_two_id ].compact.first
  end

  test "recording the final result awards gold and silver, and the whole standings show double bronze" do
    semifinal_one = @category.matches.find_by(round_number: 1, slot_position: 1)
    semifinal_two = @category.matches.find_by(round_number: 1, slot_position: 2)

    semifinal_one.record_result!(winner_registration_id: semifinal_one.registration_one_id, decision: :points, score_data: {})
    semifinal_two.record_result!(winner_registration_id: semifinal_two.registration_one_id, decision: :points, score_data: {})

    final = @category.matches.find_by(round_number: 2)
    final.reload
    final.record_result!(winner_registration_id: final.registration_one_id, decision: :points, score_data: {})
    final.reload

    assert_equal "gold", final.medal

    standings = @category.reload.medal_standings
    assert_equal final.winner_registration_id, standings[:gold].id
    assert_equal final.loser_registration_id, standings[:silver].id
    assert_equal 2, standings[:bronze].size
    refute_includes standings[:bronze].map(&:id), final.winner_registration_id
    refute_includes standings[:bronze].map(&:id), final.loser_registration_id

    # No 3rd place match was ever created.
    assert_equal 3, @category.matches.count
  end

  test "cannot record a result for a match missing an opponent" do
    incomplete_match = @category.matches.find_by(round_number: 2)

    assert_raises(Match::NotReadyForResultError) do
      incomplete_match.record_result!(winner_registration_id: incomplete_match.registration_one_id, decision: :points, score_data: {})
    end
  end

  test "winner must be one of the two participants" do
    semifinal = @category.matches.find_by(round_number: 1, slot_position: 1)
    other_registration = @registrations.find { |r| ![ semifinal.registration_one_id, semifinal.registration_two_id ].include?(r.id) }

    match = Match.new(
      tournament_category: @category,
      round_number: 1,
      slot_position: 99,
      registration_one_id: semifinal.registration_one_id,
      registration_two_id: semifinal.registration_two_id,
      winner_registration_id: other_registration.id
    )

    assert_not match.valid?
    assert_includes match.errors[:winner_registration], "must be one of the two participants"
  end
end
