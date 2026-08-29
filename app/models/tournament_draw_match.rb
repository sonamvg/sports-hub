class TournamentDrawMatch < ApplicationRecord
  belongs_to :tournament_draw
  belongs_to :red_registration, class_name: "Registration", optional: true
  belongs_to :blue_registration, class_name: "Registration", optional: true

  validates :round_number, :position, presence: true
  validates :position, uniqueness: { scope: [:tournament_draw_id, :round_number] }
  validates :round_number, :position, numericality: { only_integer: true, greater_than: 0 }

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

  def red_academy_label
    academy_label(red_registration)
  end

  def blue_academy_label
    academy_label(blue_registration)
  end

  private

  def entrant_label(registration, source_position)
    return "Winner #{source_position}" if registration.blank? && round_number > 1 && source_position.present?
    return "Winner" if registration.blank? && round_number > 1
    return "Bye" if registration.blank?

    registration.athlete.full_name
  end

  def academy_label(registration)
    return "--" if registration.blank?

    registration.athlete.academy&.name || "Independent"
  end
end
