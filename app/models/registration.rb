class Registration < ApplicationRecord
  belongs_to :tournament
  belongs_to :athlete
  belongs_to :tournament_category

  enum :status, { pending: 0, approved: 1, rejected: 2, withdrawn: 3 }, default: :pending

  validates :athlete_id, uniqueness: { scope: [:tournament_id, :tournament_category_id] }
  validate :category_belongs_to_tournament

  private

  def category_belongs_to_tournament
    return if tournament.blank? || tournament_category.blank?
    errors.add(:tournament_category, "must belong to the selected tournament") if tournament_category.tournament_id != tournament_id
  end
end
