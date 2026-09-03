# Builds a single-elimination bracket for a tournament category from its
# weight-verified registrations: a pure random blind draw, with byes placed
# using the standard tournament seeding-table method so they are spread
# evenly across the bracket instead of clustered on one side.
class BracketGenerator
  Result = Struct.new(:ok, :error, keyword_init: true) do
    def success?
      ok
    end
  end

  def initialize(tournament_category)
    @category = tournament_category
  end

  def call
    return failure("The draw has already been set for this category.") if @category.draw_generated?

    registrations = @category.draw_eligible_registrations.to_a
    return failure("At least 2 weight-verified athletes are required to generate a draw.") if registrations.size < 2

    ActiveRecord::Base.transaction do
      build_bracket(registrations.shuffle)
      @category.update!(draw_generated_at: Time.current)
    end

    success
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.to_sentence)
  end

  private

  def success
    Result.new(ok: true)
  end

  def failure(message)
    Result.new(ok: false, error: message)
  end

  def build_bracket(seeded_registrations)
    bracket_size = next_power_of_two(seeded_registrations.size)
    slots = seed_order(bracket_size).map { |seed| seeded_registrations[seed - 1] }
    rounds_count = Math.log2(bracket_size).to_i

    matches_by_round = { 1 => build_round_one(slots) }
    (2..rounds_count).each do |round_number|
      matches_by_round[round_number] = build_empty_round(round_number, matches_by_round[round_number - 1].size / 2)
    end

    wire_next_match_pointers(matches_by_round, rounds_count)
    resolve_byes(matches_by_round[1])
  end

  def next_power_of_two(count)
    size = 1
    size *= 2 while size < count
    size
  end

  # Classic recursive "reflection" seeding sequence, e.g. for size 8:
  # [1, 8, 4, 5, 2, 7, 3, 6] — adjacent pairs meet in round 1, and the
  # highest (bye) seed numbers land opposite each other, never paired together.
  def seed_order(bracket_size)
    sequence = [ 1 ]
    while sequence.size < bracket_size
      total = sequence.size * 2
      sequence = sequence.flat_map { |seed| [ seed, total + 1 - seed ] }
    end
    sequence
  end

  def build_round_one(slots)
    slots.each_slice(2).with_index(1).map do |(one, two), slot_position|
      Match.create!(
        tournament_category: @category,
        round_number: 1,
        slot_position: slot_position,
        registration_one_id: one&.id,
        registration_two_id: two&.id
      )
    end
  end

  def build_empty_round(round_number, match_count)
    (1..match_count).map do |slot_position|
      Match.create!(tournament_category: @category, round_number: round_number, slot_position: slot_position)
    end
  end

  def wire_next_match_pointers(matches_by_round, rounds_count)
    (1...rounds_count).each do |round_number|
      matches_by_round[round_number].each do |match|
        next_slot_position = (match.slot_position + 1) / 2
        next_match = matches_by_round[round_number + 1].find { |m| m.slot_position == next_slot_position }
        match.update!(next_match: next_match, next_match_slot: match.slot_position.odd? ? 1 : 2)
      end
    end
  end

  def resolve_byes(round_one_matches)
    round_one_matches.each do |match|
      present = [ match.registration_one_id, match.registration_two_id ].compact
      next unless present.size == 1

      match.resolve_as_bye!(winner_registration_id: present.first)
    end
  end
end
