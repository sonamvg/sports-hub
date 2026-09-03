require "test_helper"

class MatchScoreDeciderTest < ActiveSupport::TestCase
  test "decides the match after 2 clean round wins, round 3 optional" do
    result = MatchScoreDecider.new([
      { points_one: 2, points_two: 6 },
      { points_one: 4, points_two: 6 },
      {}
    ]).call

    assert result.success?
    assert_equal "two", result.winner_side
    assert_equal({ "one" => 0, "two" => 2 }, result.score_data["rounds_won"])
  end

  test "requires round 3 when split 1-1 after two rounds" do
    result = MatchScoreDecider.new([
      { points_one: 5, points_two: 3 },
      { points_one: 2, points_two: 6 }
    ]).call

    assert_not result.success?
    assert_match(/round 3/i, result.error)
  end

  test "round 3 decides the match when split 1-1" do
    result = MatchScoreDecider.new([
      { points_one: 5, points_two: 3 },
      { points_one: 2, points_two: 6 },
      { points_one: 7, points_two: 1 }
    ]).call

    assert result.success?
    assert_equal "one", result.winner_side
  end

  test "a tied round requires a superiority call" do
    result = MatchScoreDecider.new([
      { points_one: 4, points_two: 4 },
      { points_one: 3, points_two: 1 }
    ]).call

    assert_not result.success?
    assert_match(/superiority/i, result.error)
  end

  test "superiority call breaks a tied round" do
    result = MatchScoreDecider.new([
      { points_one: 4, points_two: 4, superiority_winner: "two" },
      { points_one: 3, points_two: 1 },
      { points_one: 1, points_two: 5 }
    ]).call

    assert result.success?
    assert_equal "two", result.winner_side
    assert_equal "two", result.score_data["rounds"][0]["round_winner"]
  end

  test "requires round 1 and round 2 scores" do
    result = MatchScoreDecider.new([ { points_one: 5, points_two: 3 } ]).call

    assert_not result.success?
    assert_match(/round 2/i, result.error)
  end
end
