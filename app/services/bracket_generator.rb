# Builds a single-elimination bracket for a tournament category from its
# weight-verified registrations: a random blind draw, with byes placed using
# the standard tournament seeding-table method so they are spread evenly
# across the bracket instead of clustered on one side.
#
# Clubmates are kept apart in round 1 wherever possible — two athletes from
# the same academy are only ever paired there if the field makes it
# unavoidable (e.g. one academy makes up more than half the bracket). From
# round 2 onward, pairings are whoever wins through, with no such constraint.
class BracketGenerator
  # Cheap to try many random draws and keep the best one, so this only needs
  # to be "generous enough" rather than exhaustive — real fields are small
  # enough that a same-academy-free arrangement, when one exists, turns up
  # quickly.
  MAX_DRAW_ATTEMPTS = 200

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
    return failure("The draw cannot be set because the tournament has been #{@category.tournament.status}.") if @category.tournament.closed_out?

    registrations = @category.draw_eligible_registrations.to_a
    return failure("At least 2 weight-verified athletes are required to generate a draw.") if registrations.size < 2

    ActiveRecord::Base.transaction do
      build_bracket(best_effort_draw(registrations))
      @category.update!(draw_generated_at: Time.current)
    end

    success
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.to_sentence)
  end

  private

  # Tries several random draws and keeps whichever pairs the fewest
  # clubmates together in round 1, stopping early the moment one has none.
  def best_effort_draw(registrations)
    best = registrations.shuffle
    best_conflicts = round_one_academy_conflicts(best)
    return best if best_conflicts.zero?

    (MAX_DRAW_ATTEMPTS - 1).times do
      candidate = registrations.shuffle
      candidate_conflicts = round_one_academy_conflicts(candidate)
      next unless candidate_conflicts < best_conflicts

      best = candidate
      best_conflicts = candidate_conflicts
      break if best_conflicts.zero?
    end

    best
  end

  def round_one_academy_conflicts(shuffled_registrations)
    bracket_size = next_power_of_two(shuffled_registrations.size)
    slots = seed_order(bracket_size).map { |seed| shuffled_registrations[seed - 1] }

    slots.each_slice(2).count do |one, two|
      next false unless one && two

      key = academy_key(one)
      key.present? && key == academy_key(two)
    end
  end

  # Groups by the real academy when the athlete has one; falls back to the
  # free-text "unregistered academy" name so clubmates without a formal
  # academy record are still kept apart. Athletes with neither are never
  # treated as a conflict with each other.
  def academy_key(registration)
    athlete = registration.athlete
    athlete.academy_id || athlete.external_academy_name.to_s.downcase.presence
  end

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
