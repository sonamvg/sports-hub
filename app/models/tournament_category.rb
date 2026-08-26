class TournamentCategory < ApplicationRecord
  before_validation :assign_generated_name
  before_validation :assign_category_key

  belongs_to :tournament
  has_many :registrations, dependent: :restrict_with_error

  validates :name, :event_type, :category_key, presence: true
  validates :category_key, uniqueness: { scope: :tournament_id, message: "already exists for this tournament" }
  validates :age_min, :age_max, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :weight_min, :weight_max, numericality: { greater_than: 0 }, allow_nil: true
  validates :registration_fee, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :age_max_not_below_min
  validate :weight_max_not_below_min

  def effective_registration_fee
    registration_fee.presence || tournament.registration_fee.presence || 0
  end

  def fee_label
    "#{tournament.currency.presence || "INR"} #{format_currency(effective_registration_fee)}"
  end

  def generated_name
    [
      event_type.presence&.humanize&.titleize,
      gender.presence&.humanize&.titleize,
      age_label,
      weight_label,
      belt_label
    ].compact.join(" ").presence || "Tournament category"
  end

  private

  def assign_generated_name
    self.name = generated_name
  end

  def assign_category_key
    self.category_key = [
      event_type,
      gender,
      age_min,
      age_max,
      format_number(weight_min),
      format_number(weight_max),
      belt_min,
      belt_max
    ].map { |value| value.to_s.strip.downcase }.join("|")
  end

  def age_label
    if age_min.present? && age_max.present?
      "Age #{age_min}-#{age_max}"
    elsif age_min.present?
      "Age #{age_min}+"
    elsif age_max.present?
      "Age U#{age_max}"
    end
  end

  def weight_label
    if weight_min.present? && weight_max.present?
      "#{format_number(weight_min)}-#{format_number(weight_max)}kg"
    elsif weight_min.present?
      "Over #{format_number(weight_min)}kg"
    elsif weight_max.present?
      "U#{format_number(weight_max)}"
    end
  end

  def belt_label
    if belt_min.present? && belt_max.present?
      "#{belt_min.titleize}-#{belt_max.titleize}"
    elsif belt_min.present?
      "#{belt_min.titleize}+"
    elsif belt_max.present?
      "Up to #{belt_max.titleize}"
    end
  end

  def format_number(number)
    return if number.blank?

    decimal = number.to_d
    decimal.frac.zero? ? decimal.to_i.to_s : decimal.to_s("F").sub(/0+\z/, "").sub(/\.\z/, "")
  end

  def format_currency(amount)
    decimal = amount.to_d
    decimal.frac.zero? ? decimal.to_i.to_s : format("%.2f", decimal)
  end

  def age_max_not_below_min
    return if age_min.blank? || age_max.blank?
    errors.add(:age_max, "cannot be below minimum age") if age_max < age_min
  end

  def weight_max_not_below_min
    return if weight_min.blank? || weight_max.blank?
    errors.add(:weight_max, "cannot be below minimum weight") if weight_max < weight_min
  end
end
