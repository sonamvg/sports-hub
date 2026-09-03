# Decides a Kyorugi match winner from up to 3 independently-scored rounds
# (best of 3 rounds, not cumulative points). A round tied on points requires
# a manual superiority call (which athlete showed the more advanced technique).
class MatchScoreDecider
  SIDES = %w[one two].freeze

  Result = Struct.new(:ok, :winner_side, :score_data, :error, keyword_init: true) do
    def success?
      ok
    end
  end

  # rounds_params: array of up to 3 hashes with keys :points_one, :points_two, :superiority_winner
  def initialize(rounds_params)
    @rounds_params = Array(rounds_params)
  end

  def call
    rounds, error = build_rounds
    return failure(error) if error

    wins = tally(rounds)
    winner_side = decisive_side(wins)
    return failure("Enter round 3 to decide the match — rounds are split 1-1.") if winner_side.nil?

    Result.new(ok: true, winner_side: winner_side, score_data: { "rounds" => rounds, "rounds_won" => wins })
  end

  private

  def failure(message)
    Result.new(ok: false, error: message)
  end

  def build_rounds
    rounds = []

    (1..3).each do |round_number|
      params = @rounds_params[round_number - 1] || {}
      points_one = params[:points_one].presence
      points_two = params[:points_two].presence

      if points_one.blank? && points_two.blank?
        return [ nil, "Round #{round_number} score is required." ] if round_number <= 2

        rounds << { "round" => round_number, "points_one" => nil, "points_two" => nil, "round_winner" => nil }
        next
      end

      return [ nil, "Round #{round_number} needs both athletes' points." ] if points_one.blank? || points_two.blank?

      points_one = points_one.to_i
      points_two = points_two.to_i

      round_winner =
        if points_one == points_two
          superiority = params[:superiority_winner].presence
          return [ nil, "Round #{round_number} is tied — select who showed superiority." ] unless SIDES.include?(superiority)

          superiority
        else
          points_one > points_two ? "one" : "two"
        end

      rounds << { "round" => round_number, "points_one" => points_one, "points_two" => points_two, "round_winner" => round_winner }
    end

    [ rounds, nil ]
  end

  def tally(rounds)
    wins = { "one" => 0, "two" => 0 }
    rounds.each { |round| wins[round["round_winner"]] += 1 if round["round_winner"] }
    wins
  end

  def decisive_side(wins)
    return "one" if wins["one"] >= 2
    return "two" if wins["two"] >= 2

    nil
  end
end
