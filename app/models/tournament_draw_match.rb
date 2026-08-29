class TournamentDrawMatch < ApplicationRecord
  belongs_to :tournament_draw
  belongs_to :red_registration, class_name: "Registration", optional: true
  belongs_to :blue_registration, class_name: "Registration", optional: true
  belongs_to :winner_registration, class_name: "Registration", optional: true
  belongs_to :completed_by, class_name: "User", optional: true

  HEAD_GUARD_COLORS = %w[red blue].freeze
  SCORE_ATTRIBUTES = %i[
    red_round_1_points blue_round_1_points
    red_round_2_points blue_round_2_points
    red_round_3_points blue_round_3_points
  ].freeze

  validates :round_number, :position, presence: true
  validates :position, uniqueness: { scope: [:tournament_draw_id, :round_number] }
  validates :round_number, :position, numericality: { only_integer: true, greater_than: 0 }
  validates :red_head_guard_color, :blue_head_guard_color, inclusion: { in: HEAD_GUARD_COLORS }
  validates(*SCORE_ATTRIBUTES, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true)
  validate :head_guard_colors_must_be_distinct
  validate :winner_must_be_in_match

  def round_label
    return "Final" if round_number == tournament_draw.round_count
    return "Semi-final" if round_number == tournament_draw.round_count - 1

    "Round #{round_number}"
  end

  def red_label
    entrant_label(red_registration, red_source_match_position)
  end

  def blue_label
    entrant_label(blue_registration, blue_source_match_position)
  end

  def ready_for_result?
    red_registration.present? && blue_registration.present?
  end

  def complete?
    winner_registration.present?
  end

  def red_total_points
    [red_round_1_points, red_round_2_points, red_round_3_points].compact.sum
  end

  def blue_total_points
    [blue_round_1_points, blue_round_2_points, blue_round_3_points].compact.sum
  end

  def red_round_wins
    round_winners.count(:red)
  end

  def blue_round_wins
    round_winners.count(:blue)
  end

  def round_winners
    [
      round_winner(red_round_1_points, blue_round_1_points),
      round_winner(red_round_2_points, blue_round_2_points),
      round_winner(red_round_3_points, blue_round_3_points)
    ].compact
  end

  def score_complete?
    SCORE_ATTRIBUTES.all? { |attribute| public_send(attribute).present? }
  end

  def record_result!(actor:, attributes:)
    assign_attributes(attributes)
    winner = calculated_winner
    return false if errors.any?

    self.completed_by = actor
    self.completed_at = Time.current
    self.winner_registration = winner

    return false unless save

    advance_winner!
    true
  end

  def assign_bye_winner!
    return unless bye?

    self.winner_registration = red_registration || blue_registration
    self.completed_at ||= Time.current
    save!
    advance_winner!
  end

  private

  def entrant_label(registration, source_position)
    return "Winner #{source_position}" if registration.blank? && round_number > 1 && source_position.present?
    return "Winner" if registration.blank? && round_number > 1
    return "Bye" if registration.blank?

    registration.athlete.full_name
  end

  def calculated_winner
    return red_registration if blue_registration.blank?
    return blue_registration if red_registration.blank?
    unless score_complete?
      errors.add(:base, "Enter points for all three rounds")
      return nil
    end
    return red_registration if red_round_wins > blue_round_wins
    return blue_registration if blue_round_wins > red_round_wins
    return winner_registration if winner_registration_id.present?

    errors.add(:winner_registration, "must be selected when set wins are tied")
    nil
  end

  def round_winner(red_points, blue_points)
    return if red_points.blank? || blue_points.blank?
    return :red if red_points > blue_points
    return :blue if blue_points > red_points
  end

  def advance_winner!
    return if winner_registration.blank?
    return if round_number >= tournament_draw.round_count

    next_match = tournament_draw.tournament_draw_matches.find_by(
      round_number: round_number + 1,
      position: ((position - 1) / 2) + 1
    )
    return if next_match.blank?

    if position.odd?
      next_match.update!(red_registration: winner_registration)
    else
      next_match.update!(blue_registration: winner_registration)
    end
  end

  def head_guard_colors_must_be_distinct
    return if red_head_guard_color.blank? || blue_head_guard_color.blank?

    errors.add(:blue_head_guard_color, "must be different from red head guard color") if red_head_guard_color == blue_head_guard_color
  end

  def winner_must_be_in_match
    return if winner_registration.blank?
    return if [red_registration_id, blue_registration_id].include?(winner_registration_id)

    errors.add(:winner_registration, "must be one of the athletes in this match")
  end
end
