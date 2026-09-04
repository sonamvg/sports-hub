class TournamentCategory < ApplicationRecord
  before_validation :assign_generated_name
  before_validation :assign_category_key

  belongs_to :tournament
  has_many :registrations, dependent: :restrict_with_error
  has_many :matches, dependent: :destroy

  DEFAULT_CATEGORY_TEMPLATES = [
    { key: "sub-junior-female-u18", event_type: "kyorugi", gender: "female", age_min: 8, age_max: 11, weight_max: 18 },
    { key: "sub-junior-female-u21", event_type: "kyorugi", gender: "female", age_min: 8, age_max: 11, weight_min: 18, weight_max: 21 },
    { key: "sub-junior-female-u24", event_type: "kyorugi", gender: "female", age_min: 8, age_max: 11, weight_min: 21, weight_max: 24 },
    { key: "sub-junior-male-u18", event_type: "kyorugi", gender: "male", age_min: 8, age_max: 11, weight_max: 18 },
    { key: "sub-junior-male-u21", event_type: "kyorugi", gender: "male", age_min: 8, age_max: 11, weight_min: 18, weight_max: 21 },
    { key: "sub-junior-male-u24", event_type: "kyorugi", gender: "male", age_min: 8, age_max: 11, weight_min: 21, weight_max: 24 },
    { key: "cadet-female-u33", event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 33 },
    { key: "cadet-female-u37", event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37 },
    { key: "cadet-female-u41", event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 37, weight_max: 41 },
    { key: "cadet-male-u33", event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_max: 33 },
    { key: "cadet-male-u37", event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37 },
    { key: "cadet-male-u41", event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 37, weight_max: 41 },
    { key: "junior-female-u44", event_type: "kyorugi", gender: "female", age_min: 15, age_max: 17, weight_max: 44 },
    { key: "junior-female-u49", event_type: "kyorugi", gender: "female", age_min: 15, age_max: 17, weight_min: 44, weight_max: 49 },
    { key: "junior-female-u55", event_type: "kyorugi", gender: "female", age_min: 15, age_max: 17, weight_min: 49, weight_max: 55 },
    { key: "junior-male-u45", event_type: "kyorugi", gender: "male", age_min: 15, age_max: 17, weight_max: 45 },
    { key: "junior-male-u51", event_type: "kyorugi", gender: "male", age_min: 15, age_max: 17, weight_min: 45, weight_max: 51 },
    { key: "junior-male-u55", event_type: "kyorugi", gender: "male", age_min: 15, age_max: 17, weight_min: 51, weight_max: 55 },
    { key: "senior-female-u49", event_type: "kyorugi", gender: "female", age_min: 18, weight_max: 49 },
    { key: "senior-female-u57", event_type: "kyorugi", gender: "female", age_min: 18, weight_min: 49, weight_max: 57 },
    { key: "senior-female-u67", event_type: "kyorugi", gender: "female", age_min: 18, weight_min: 57, weight_max: 67 },
    { key: "senior-male-u58", event_type: "kyorugi", gender: "male", age_min: 18, weight_max: 58 },
    { key: "senior-male-u68", event_type: "kyorugi", gender: "male", age_min: 18, weight_min: 58, weight_max: 68 },
    { key: "senior-male-u80", event_type: "kyorugi", gender: "male", age_min: 18, weight_min: 68, weight_max: 80 },
    { key: "individual-poomsae-female-cadet", event_type: "poomsae", gender: "female", age_min: 12, age_max: 14 },
    { key: "individual-poomsae-male-cadet", event_type: "poomsae", gender: "male", age_min: 12, age_max: 14 },
    { key: "individual-poomsae-female-junior", event_type: "poomsae", gender: "female", age_min: 15, age_max: 17 },
    { key: "individual-poomsae-male-junior", event_type: "poomsae", gender: "male", age_min: 15, age_max: 17 },
    { key: "individual-poomsae-female-senior", event_type: "poomsae", gender: "female", age_min: 18 },
    { key: "individual-poomsae-male-senior", event_type: "poomsae", gender: "male", age_min: 18 }
  ].freeze

  validates :name, :event_type, :category_key, presence: true
  validates :category_key, uniqueness: { scope: :tournament_id, message: "already exists for this tournament" }
  validates :age_min, :age_max, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :weight_min, :weight_max, numericality: { greater_than: 0 }, allow_nil: true
  validate :age_max_not_below_min
  validate :weight_max_not_below_min

  def effective_registration_fee
    tournament.registration_fee.presence || 0
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

  def self.default_template_for(key)
    DEFAULT_CATEGORY_TEMPLATES.find { |template| template[:key] == key.to_s }
  end

  def draw_generated?
    draw_generated_at.present?
  end

  def draw_locked?
    draw_generated? && matches.completed.exists?
  end

  def draw_eligible_registrations
    registrations.weight_verified.includes(athlete: :academy)
  end

  def reset_draw!
    raise "Draw is locked and cannot be regenerated" if draw_locked?

    transaction do
      # Delete earlier rounds first: a round-r match's next_match_id points
      # forward to round r+1, so the referencing row must go before its target.
      matches.order(round_number: :asc).destroy_all
      update!(draw_generated_at: nil)
    end
  end

  def eligibility_errors_for(athlete, as_of: Date.current, weight: nil)
    errors = []

    if gender.present? && athlete.gender.present? && athlete.gender != gender
      errors << "athlete's gender does not match this category"
    end

    if age_min.present? || age_max.present?
      if athlete.date_of_birth.blank?
        errors << "athlete's date of birth is required for this category"
      else
        athlete_age = age_on(athlete.date_of_birth, as_of || Date.current)
        errors << "athlete's age does not match this category" if (age_min.present? && athlete_age < age_min) || (age_max.present? && athlete_age > age_max)
      end
    end

    if belt_min.present? || belt_max.present?
      if athlete.belt.blank?
        errors << "athlete's belt rank is required for this category"
      else
        belt_index = Athlete::BELTS.index(athlete.belt)
        min_index = belt_min.present? ? Athlete::BELTS.index(belt_min) : nil
        max_index = belt_max.present? ? Athlete::BELTS.index(belt_max) : nil
        errors << "athlete's belt rank does not match this category" if belt_index.nil? || (min_index && belt_index < min_index) || (max_index && belt_index > max_index)
      end
    end

    if weight.present? && (weight_min.present? || weight_max.present?)
      measured_weight = weight.to_d
      errors << "athlete's weight does not match this category" if (weight_min.present? && measured_weight < weight_min) || (weight_max.present? && measured_weight > weight_max)
    end

    errors
  end

  def medal_standings
    final = matches.find_by(medal: :gold)
    return {} unless final

    {
      gold: final.winner_registration,
      silver: registration_for(final.loser_registration_id),
      bronze: matches.where(medal: :bronze).filter_map { |match| registration_for(match.loser_registration_id) }
    }
  end

  private

  def registration_for(registration_id)
    return if registration_id.blank?

    Registration.find_by(id: registration_id)
  end

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

  def age_on(date_of_birth, as_of_date)
    age = as_of_date.year - date_of_birth.year
    age -= 1 if as_of_date < date_of_birth + age.years
    age
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
