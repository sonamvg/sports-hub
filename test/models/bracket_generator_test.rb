require "test_helper"

class BracketGeneratorTest < ActiveSupport::TestCase
  setup do
    @organizer = User.create!(name: "Organizer", email: "bracket-organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(name: "Bracket Open", organizer: @organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    @category = @tournament.tournament_categories.create!(event_type: "kyorugi", gender: "male", age_min: 18)
  end

  test "requires at least 2 weight-verified registrations" do
    create_weight_verified_registration(tournament: @tournament, category: @category, email: "solo@example.test")

    result = BracketGenerator.new(@category).call

    assert_not result.success?
    assert_match(/at least 2/i, result.error)
    assert_not @category.reload.draw_generated?
  end

  test "refuses to regenerate an already-generated draw" do
    seed_registrations(3)
    BracketGenerator.new(@category).call

    result = BracketGenerator.new(@category).call

    assert_not result.success?
    assert_match(/already been set/i, result.error)
  end

  [ 2, 3, 4, 5, 6, 7, 8, 9, 11, 16 ].each do |count|
    test "builds a valid single-elimination bracket for #{count} entrants" do
      registrations = seed_registrations(count)

      result = BracketGenerator.new(@category).call
      assert result.success?, result.error

      @category.reload
      assert @category.draw_generated?

      matches = @category.matches.order(:round_number, :slot_position)
      bracket_size = 1
      bracket_size *= 2 while bracket_size < count
      rounds_count = Math.log2(bracket_size).to_i

      assert_equal rounds_count, matches.map(&:round_number).max

      # No round-1 match ever pairs two byes together.
      round_one = matches.select { |m| m.round_number == 1 }
      assert_equal bracket_size / 2, round_one.size
      round_one.each do |match|
        present = [ match.registration_one_id, match.registration_two_id ].compact
        assert present.size >= 1, "match #{match.slot_position} has no participant at all"
      end

      # Every real registration appears exactly once across round 1.
      seeded_ids = round_one.flat_map { |m| [ m.registration_one_id, m.registration_two_id ] }.compact
      assert_equal registrations.map(&:id).sort, seeded_ids.sort

      # Byes are already resolved and their winners advanced.
      byes = round_one.select(&:bye?)
      byes.each do |bye_match|
        assert bye_match.winner_registration_id.present?
        next_match = matches.find { |m| m.id == bye_match.next_match_id }
        next_match_ids = [ next_match.registration_one_id, next_match.registration_two_id ]
        assert_includes next_match_ids, bye_match.winner_registration_id
      end

      # The final round has exactly one match with no next_match.
      final_matches = matches.select { |m| m.next_match_id.nil? }
      assert_equal 1, final_matches.size
      assert_equal rounds_count, final_matches.first.round_number
    end
  end

  private

  def seed_registrations(count)
    count.times.map { |i| create_weight_verified_registration(tournament: @tournament, category: @category, email: "bracket-#{count}-#{i}@example.test") }
  end
end
