class TournamentDraw < ApplicationRecord
  belongs_to :tournament
  belongs_to :tournament_category
  belongs_to :generated_by, class_name: "User"
  has_many :tournament_draw_matches, dependent: :destroy

  scope :active, -> { where(superseded_at: nil) }

  validates :tournament_category_id, uniqueness: { scope: :tournament_id, conditions: -> { where(superseded_at: nil) } }, unless: :superseded?
  validates :bracket_size, numericality: { only_integer: true, greater_than_or_equal_to: 2 }
  validates :round_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :entry_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validate :category_belongs_to_tournament

  def superseded?
    superseded_at.present?
  end

  def matches_by_round
    tournament_draw_matches
      .includes(
        red_registration: { athlete: :academy },
        blue_registration: { athlete: :academy },
        winner_registration: :athlete
      )
      .order(:round_number, :position)
      .group_by(&:round_number)
  end

  private

  def category_belongs_to_tournament
    return if tournament.blank? || tournament_category.blank?

    errors.add(:tournament_category, "must belong to the tournament") if tournament_category.tournament_id != tournament_id
  end
end
