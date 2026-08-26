class Registration < ApplicationRecord
  belongs_to :tournament
  belongs_to :athlete
  belongs_to :tournament_category
  has_many :registration_action_logs, dependent: :destroy
  has_one_attached :payment_receipt

  enum :status, { pending: 0, approved: 1, rejected: 2, withdrawn: 3 }, default: :pending

  validates :athlete_id, uniqueness: { scope: [:tournament_id, :tournament_category_id] }
  validate :payment_receipt_required
  validate :category_belongs_to_tournament

  def review!(actor:, status:)
    from_status = self.status
    update!(status: status, verified_at: Time.current)
    registration_action_logs.create!(
      actor: actor,
      action: status.to_s,
      from_status: from_status,
      to_status: self.status
    )
  end

  private

  def category_belongs_to_tournament
    return if tournament.blank? || tournament_category.blank?
    errors.add(:tournament_category, "must belong to the selected tournament") if tournament_category.tournament_id != tournament_id
  end

  def payment_receipt_required
    errors.add(:payment_receipt, "must be uploaded") unless payment_receipt.attached?
  end
end
