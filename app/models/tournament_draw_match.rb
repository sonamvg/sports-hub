class TournamentDrawMatch < ApplicationRecord
  belongs_to :tournament_draw
  belongs_to :red_registration, class_name: "Registration", optional: true
  belongs_to :blue_registration, class_name: "Registration", optional: true
  belongs_to :winner_registration, class_name: "Registration", optional: true
  belongs_to :completed_by, class_name: "User", optional: true

  before_validation :clear_unused_round_decisions

  HEAD_GUARD_COLORS = %w[red blue].freeze
  TOP_CHEST_GUARD_COLOR = "blue"
  BOTTOM_CHEST_GUARD_COLOR = "red"
  SCORE_ATTRIBUTES = %i[
    red_round_1_points blue_round_1_points
    red_round_2_points blue_round_2_points
    red_round_3_points blue_round_3_points
  ].freeze
  ROUND_DECISION_ATTRIBUTES = %i[
    round_1_winner_side
    round_2_winner_side
    round_3_winner_side
  ].freeze
  WINNER_SIDES = %w[red blue].freeze

  validates :round_number, :position, presence: true
  validates :position, uniqueness: { scope: [:tournament_draw_id, :round_number] }
  validates :round_number, :position, numericality: { only_integer: true, greater_than: 0 }
  validates :red_head_guard_color, :blue_head_guard_color, inclusion: { in: HEAD_GUARD_COLORS }
  validates(*SCORE_ATTRIBUTES, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true)
  validates(*ROUND_DECISION_ATTRIBUTES, inclusion: { in: WINNER_SIDES }, allow_nil: true)
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

  def top_chest_guard_color
    TOP_CHEST_GUARD_COLOR
  end

  def bottom_chest_guard_color
    BOTTOM_CHEST_GUARD_COLOR
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
      round_winner(red_round_1_points, blue_round_1_points, round_1_winner_side),
      round_winner(red_round_2_points, blue_round_2_points, round_2_winner_side),
      round_winner(red_round_3_points, blue_round_3_points, round_3_winner_side)
    ].compact
  end

  def score_complete?
    SCORE_ATTRIBUTES.all? { |attribute| public_send(attribute).present? }
  end

  def set_wins_tied?
    score_complete? && red_round_wins == blue_round_wins
  end

  def round_points_tied?(round)
    red_points = public_send(:"red_round_#{round}_points")
    blue_points = public_send(:"blue_round_#{round}_points")

    red_points.present? && blue_points.present? && red_points == blue_points
  end

  def round_winner_side(round)
    round_winner(
      public_send(:"red_round_#{round}_points"),
      public_send(:"blue_round_#{round}_points"),
      public_send(:"round_#{round}_winner_side")
    )
  end

  def ready_to_freeze?
    score_complete? && (1..3).all? { |round| !round_points_tied?(round) || public_send(:"round_#{round}_winner_side").present? }
  end

  def result_label_for(registration)
    return if registration.blank? || winner_registration.blank?

    if winner_registration_id == registration.id
      winner_stage_label || "Won"
    else
      loser_stage_label || "Lost"
    end
  end

  def set_score_for(registration)
    return unless registration

    if red_registration_id == registration.id
      "#{red_round_wins}-#{blue_round_wins}"
    elsif blue_registration_id == registration.id
      "#{blue_round_wins}-#{red_round_wins}"
    end
  end

  def point_score_for(registration)
    return unless registration

    if red_registration_id == registration.id
      "#{red_total_points}-#{blue_total_points}"
    elsif blue_registration_id == registration.id
      "#{blue_total_points}-#{red_total_points}"
    end
  end

  def record_result!(actor:, attributes:)
    if complete?
      errors.add(:base, "Result is frozen and cannot be edited")
      return false
    end

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

  def save_score_draft!(attributes:)
    if complete?
      errors.add(:base, "Result is frozen and cannot be edited")
      return false
    end

    assign_attributes(score_attributes_from(attributes))
    save
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

  def score_attributes_from(attributes)
    attributes.to_h.symbolize_keys.slice(*(SCORE_ATTRIBUTES + ROUND_DECISION_ATTRIBUTES))
  end

  def calculated_winner
    return red_registration if blue_registration.blank?
    return blue_registration if red_registration.blank?
    unless score_complete?
      errors.add(:base, "Enter points for all three rounds")
      return nil
    end
    return nil unless round_tie_decisions_complete?

    return red_registration if red_round_wins > blue_round_wins
    return blue_registration if blue_round_wins > red_round_wins

    errors.add(:base, "Unable to decide winner from round results")
    nil
  end

  def winner_stage_label
    return "Gold" if final?

    "Advanced"
  end

  def loser_stage_label
    return "Silver" if final?
    return "Bronze" if semi_final?

    "Lost"
  end

  def final?
    round_number == tournament_draw.round_count
  end

  def semi_final?
    round_number == tournament_draw.round_count - 1
  end

  def round_winner(red_points, blue_points, decision)
    return if red_points.blank? || blue_points.blank?
    return :red if red_points > blue_points
    return :blue if blue_points > red_points

    decision&.to_sym
  end

  def round_tie_decisions_complete?
    (1..3).each do |round|
      next unless round_points_tied?(round)
      next if public_send(:"round_#{round}_winner_side").present?

      errors.add(:"round_#{round}_winner_side", "must be selected when round #{round} points are tied")
      return false
    end

    true
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

  def clear_unused_round_decisions
    (1..3).each do |round|
      public_send(:"round_#{round}_winner_side=", nil) unless round_points_tied?(round)
    end
  end
end
