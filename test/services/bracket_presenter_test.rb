require "test_helper"

class BracketPresenterTest < ActiveSupport::TestCase
  setup do
    @organizer = User.create!(name: "Organizer", email: "presenter-organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(name: "Presenter Open", organizer: @organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    @category = @tournament.tournament_categories.create!(event_type: "kyorugi", gender: "male", age_min: 18)
  end

  # Regression test: brackets-viewer.js treats a non-nil `position` on a round 2+
  # opponent as a signal that this is "Toornament-imported" data, and rebuilds
  # round 1's match order by looking up round-1 matches whose `number` equals
  # that position. Since we use `position` to mean "seed number" (1..bracket_size)
  # rather than "originating match number" (1..matches_per_round), setting it on
  # round 2+ opponents made the library silently duplicate/drop round-1 matches.
  test "only round 1 opponents carry a seed position" do
    7.times { |i| create_weight_verified_registration(tournament: @tournament, category: @category, email: "presenter-#{i}@example.test") }
    BracketGenerator.new(@category).call
    @category.reload

    # Complete one round-1 match so a later round has a fully-decided opponent too,
    # which is exactly the combination that triggered the bug.
    scored_match = @category.matches.find { |m| m.round_number == 1 && m.ready_for_result? }
    scored_match.record_result!(winner_registration_id: scored_match.registration_one_id, decision: :points, score_data: { "rounds_won" => { "one" => 2, "two" => 0 } })

    data = BracketPresenter.new(@category.reload).as_json

    data[:matches].each do |match|
      next if match[:round_id] == 1

      [ match[:opponent1], match[:opponent2] ].compact.each do |opponent|
        assert_not opponent.key?(:position), "round #{match[:round_id]} opponent must not carry a position: #{opponent.inspect}"
      end
    end

    round_one_matches = data[:matches].select { |m| m[:round_id] == 1 }
    assert_equal 4, round_one_matches.size

    # Every round-1 registration must appear exactly once across round 1 (no duplicates, none dropped).
    seeded_ids = round_one_matches.flat_map { |m| [ m[:opponent1], m[:opponent2] ] }.compact.map { |o| o[:id] }.compact
    assert_equal @category.draw_eligible_registrations.pluck(:id).sort, seeded_ids.sort
  end
end
