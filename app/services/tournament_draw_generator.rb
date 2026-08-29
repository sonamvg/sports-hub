class TournamentDrawGenerator
  Result = Struct.new(:draws, :skipped_categories, :superseded_draws_count, keyword_init: true)

  def initialize(tournament:, generated_by:)
    @tournament = tournament
    @generated_by = generated_by
  end

  def call
    draws = []
    skipped_categories = []
    superseded_draws_count = 0

    TournamentDraw.transaction do
      superseded_draws_count = supersede_active_draws

      tournament.tournament_categories.order(:name).each do |category|
        registrations = draw_ready_registrations(category)
        if registrations.empty?
          skipped_categories << category
          next
        end

        draws << create_draw(category, registrations)
      end
    end

    Result.new(draws: draws, skipped_categories: skipped_categories, superseded_draws_count: superseded_draws_count)
  end

  private

  attr_reader :tournament, :generated_by

  def supersede_active_draws
    tournament.tournament_draws.active.update_all(superseded_at: Time.current, updated_at: Time.current)
  end

  def draw_ready_registrations(category)
    tournament.registrations
      .weight_verified
      .where(tournament_category: category)
      .includes(athlete: :academy)
      .order(:created_at, :id)
      .to_a
  end

  def create_draw(category, registrations)
    bracket_size = next_power_of_two(registrations.size)
    round_count = Math.log2(bracket_size).to_i
    draw = tournament.tournament_draws.create!(
      tournament_category: category,
      generated_by: generated_by,
      bracket_size: bracket_size,
      round_count: round_count,
      entry_count: registrations.size,
      generated_at: Time.current
    )

    create_first_round(draw, registrations, bracket_size)
    create_later_rounds(draw, bracket_size, round_count)
    advance_bye_winners(draw)
    draw
  end

  def create_first_round(draw, registrations, bracket_size)
    pairings = first_round_pairings(registrations, bracket_size)

    pairings.each_with_index do |pairing, index|
      draw.tournament_draw_matches.create!(
        round_number: 1,
        position: index + 1,
        red_registration: pairing.first,
        blue_registration: pairing.second,
        bye: pairing.first.blank? || pairing.second.blank?,
        **default_chest_guard_colors
      )
    end
  end

  def advance_bye_winners(draw)
    draw.tournament_draw_matches.where(bye: true).find_each(&:assign_bye_winner!)
  end

  def create_later_rounds(draw, bracket_size, round_count)
    2.upto(round_count) do |round_number|
      match_count = bracket_size / (2**round_number)
      match_count.times do |index|
        draw.tournament_draw_matches.create!(
          round_number: round_number,
          position: index + 1,
          red_source_match_position: (index * 2) + 1,
          blue_source_match_position: (index * 2) + 2,
          **default_chest_guard_colors
        )
      end
    end
  end

  def first_round_pairings(registrations, bracket_size)
    match_count = bracket_size / 2
    bye_count = bracket_size - registrations.size
    athletes_to_pair = registrations.shuffle
    pair_count = match_count - bye_count
    pairings = []

    pair_count.times do
      first = athletes_to_pair.shift
      different_academy_indexes = athletes_to_pair.each_index.select { |index| different_academy?(first, athletes_to_pair[index]) }
      second_index = different_academy_indexes.sample || rand(athletes_to_pair.size)
      second = athletes_to_pair.delete_at(second_index)
      pairings << [first, second]
    end

    athletes_to_pair.each { |registration| pairings << [registration, nil] }
    pairings << [nil, nil] while pairings.size < match_count
    balance_bracket(pairings)
  end

  def balance_bracket(pairings)
    pairings.shuffle
  end

  def different_academy?(first, second)
    academy_key(first) != academy_key(second)
  end

  def academy_key(registration)
    athlete = registration.athlete
    return "academy:#{athlete.academy_id}" if athlete.academy_id.present?

    "external:#{athlete.external_academy_name.to_s.downcase.squish.presence || "independent:#{athlete.id}"}"
  end

  def next_power_of_two(number)
    power = 2
    power *= 2 while power < number
    power
  end

  def default_chest_guard_colors
    { red_head_guard_color: "blue", blue_head_guard_color: "red" }
  end
end
