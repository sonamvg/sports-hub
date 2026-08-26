class Registration < ApplicationRecord
  belongs_to :tournament
  belongs_to :athlete
  belongs_to :tournament_category
  has_many :registration_action_logs, dependent: :destroy
  has_many :registration_weight_checks, dependent: :destroy
  has_one_attached :payment_receipt

  enum :status, { pending: 0, approved: 1, rejected: 2, withdrawn: 3, weight_verified: 4, disqualified: 5 }, default: :pending

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

  def next_weight_check_attempt_number
    registration_weight_checks.maximum(:attempt_number).to_i + 1
  end

  def weight_check_attempts_remaining?
    approved? && registration_weight_checks.size < 3
  end

  def weight_within_category?(weight)
    measured_weight = weight.to_d
    min = tournament_category.weight_min
    max = tournament_category.weight_max

    (min.blank? || measured_weight >= min) && (max.blank? || measured_weight <= max)
  end

  def category_weight_range
    min = tournament_category.weight_min
    max = tournament_category.weight_max

    if min.present? && max.present?
      "#{formatted_weight(min)}-#{formatted_weight(max)} kg"
    elsif min.present?
      "Over #{formatted_weight(min)} kg"
    elsif max.present?
      "Up to #{formatted_weight(max)} kg"
    else
      "Open"
    end
  end

  private

  def category_belongs_to_tournament
    return if tournament.blank? || tournament_category.blank?
    errors.add(:tournament_category, "must belong to the selected tournament") if tournament_category.tournament_id != tournament_id
  end

  def payment_receipt_required
    errors.add(:payment_receipt, "must be uploaded") unless payment_receipt.attached?
  end

  def formatted_weight(weight)
    decimal = weight.to_d
    decimal.frac.zero? ? decimal.to_i.to_s : decimal.to_s("F").sub(/0+\z/, "").sub(/\.\z/, "")
  end
end
