class Registration < ApplicationRecord
  belongs_to :tournament
  belongs_to :athlete
  belongs_to :tournament_category
  has_many :registration_action_logs, dependent: :destroy
  has_many :registration_weight_checks, dependent: :destroy
  has_one_attached :payment_receipt

  enum :status, { pending: 0, approved: 1, rejected: 2, withdrawn: 3, weight_verified: 4, disqualified: 5, draft: 6 }, default: :pending

  validates :athlete_id, uniqueness: { scope: [:tournament_id, :tournament_category_id] }
  validate :payment_receipt_required
  validate :category_belongs_to_tournament
  before_validation :assign_fee_snapshot

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

  def fee_label
    "#{fee_currency.presence || tournament.currency.presence || "INR"} #{formatted_currency(fee_amount || 0)}"
  end

  def athlete_status_label
    case status
    when "pending" then "Application submitted"
    when "approved" then "Registered"
    when "rejected" then "Declined"
    when "weight_verified" then "Weight verified"
    when "disqualified" then "Disqualified"
    when "withdrawn" then "Withdrawn"
    when "draft" then "Draft"
    else status.to_s.humanize
    end
  end

  def athlete_status_detail
    if rejected?
      "Your registration was not approved by the tournament organiser."
    elsif weight_verified?
      "Weight check is complete. You are cleared for the draw."
    elsif disqualified?
      "Weight check is complete. This entry was disqualified."
    elsif approved?
      "Your registration has been accepted by the organiser."
    elsif pending?
      "Waiting for organiser review."
    elsif withdrawn?
      "This registration was withdrawn."
    end
  end

  def weight_check_summary
    registration_weight_checks.order(:attempt_number).map do |check|
      result = check.passed? ? "passed" : "failed"
      "Attempt #{check.attempt_number}: #{formatted_weight(check.weight)} kg #{result}"
    end
  end

  private

  def category_belongs_to_tournament
    return if tournament.blank? || tournament_category.blank?
    errors.add(:tournament_category, "must belong to the selected tournament") if tournament_category.tournament_id != tournament_id
  end

  def payment_receipt_required
    return if draft?

    errors.add(:payment_receipt, "must be uploaded") unless payment_receipt.attached?
  end

  def formatted_weight(weight)
    decimal = weight.to_d
    decimal.frac.zero? ? decimal.to_i.to_s : decimal.to_s("F").sub(/0+\z/, "").sub(/\.\z/, "")
  end

  def assign_fee_snapshot
    return if tournament.blank?

    self.fee_amount ||= tournament.registration_fee.presence || 0
    self.fee_currency ||= tournament.currency.presence || "INR"
  end

  def formatted_currency(amount)
    decimal = amount.to_d
    decimal.frac.zero? ? decimal.to_i.to_s : format("%.2f", decimal)
  end
end
