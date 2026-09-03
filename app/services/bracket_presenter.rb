# Serializes a tournament category's Match records into the JSON shape
# expected by brackets-viewer.js's `render({ stages, matches, matchGames, participants })`.
# See https://github.com/Drarig29/brackets-model for the schema this mirrors.
class BracketPresenter
  def initialize(tournament_category)
    @category = tournament_category
    @matches = tournament_category.matches.order(:round_number, :slot_position).to_a
  end

  def as_json
    {
      stages: [ stage_json ],
      matches: @matches.map { |match| match_json(match) },
      matchGames: [],
      participants: participants_json
    }
  end

  private

  def stage_json
    rounds_count = @matches.map(&:round_number).max || 0
    {
      id: @category.id,
      tournament_id: @category.tournament_id,
      name: @category.name,
      type: "single_elimination",
      number: 1,
      settings: { size: 2**rounds_count, seedOrdering: [ "natural" ] }
    }
  end

  def participants_json
    registration_ids = @matches.flat_map { |m| [ m.registration_one_id, m.registration_two_id ] }.compact.uniq
    Registration.where(id: registration_ids).includes(:athlete).map do |registration|
      { id: registration.id, tournament_id: @category.tournament_id, name: registration.athlete.full_name }
    end
  end

  def match_json(match)
    {
      id: match.id,
      stage_id: @category.id,
      group_id: 1,
      round_id: match.round_number,
      number: match.slot_position,
      child_count: 0,
      status: status_for(match),
      opponent1: opponent_json(match, "one"),
      opponent2: opponent_json(match, "two")
    }
  end

  # Status values from brackets-model: 0 locked, 1 waiting, 2 ready, 4 completed.
  def status_for(match)
    return 4 if match.completed? || match.bye?
    return 2 if match.registration_one_id.present? && match.registration_two_id.present?
    return 1 if match.registration_one_id.present? || match.registration_two_id.present?

    0
  end

  def opponent_json(match, side)
    registration_id = match.public_send("registration_#{side}_id")

    if registration_id.nil?
      # A round 1 slot with no registration is a genuine bye (no opponent will ever fill it).
      # Any later round with a nil slot is just TBD, still awaiting an earlier match's winner.
      return nil if match.round_number == 1

      return { id: nil }
    end

    # brackets-viewer only expects `position` (the seed badge) on round 1 opponents.
    # Setting it on round 2+ opponents makes the library reinterpret it as a
    # "Toornament import" hint, which rebuilds — and corrupts — round 1's display.
    opponent = match.round_number == 1 ? { id: registration_id, position: seed_numbers[registration_id] } : { id: registration_id }

    if match.bye?
      opponent[:result] = "win"
    elsif match.completed?
      rounds_won = match.score_data["rounds_won"] || {}
      opponent[:score] = rounds_won[side]
      opponent[:result] = match.winner_registration_id == registration_id ? "win" : "loss"
    end

    opponent
  end

  # Each registration's fixed seed number (1..bracket_size), derived from where
  # it was placed in round 1 — used only for the viewer's "#N" origin badges.
  def seed_numbers
    @seed_numbers ||= @matches.select { |m| m.round_number == 1 }.each_with_object({}) do |match, hash|
      hash[match.registration_one_id] = (2 * match.slot_position) - 1 if match.registration_one_id
      hash[match.registration_two_id] = 2 * match.slot_position if match.registration_two_id
    end
  end
end
