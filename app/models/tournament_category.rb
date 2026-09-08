class TournamentCategory < ApplicationRecord
  before_validation :assign_generated_name
  before_validation :assign_category_key

  belongs_to :tournament
  # Matches must be destroyed before registrations (a match references its
  # registrations by foreign key) and in ascending round order (a round's
  # next_match_id points forward to the next round, so the referencing row
  # has to go before its target) — otherwise deleting a tournament with a
  # generated draw fails on a foreign key violation. See reset_draw! below,
  # which has the same ordering constraint for the same reason.
  has_many :matches, -> { order(round_number: :asc) }, dependent: :destroy
  has_many :registrations, dependent: :destroy

  # Weight brackets per World Taekwondo age division. Each gender's array is
  # the ascending list of upper weight bounds (kg); the final bracket is
  # open-ended above the last bound. Senior Olympic uses the 4-class Olympic
  # program; Senior World Championships uses the wider 8-class program.
  KYORUGI_WEIGHT_BOUNDARIES = {
    sub_junior: {
      age_min: 8, age_max: 11,
      male: [16, 18, 21, 23, 25, 27, 29, 32, 35],
      female: [14, 16, 18, 20, 22, 24, 26, 29, 32]
    },
    cadet: {
      age_min: 12, age_max: 14,
      male: [33, 37, 41, 45, 49, 53, 57, 61, 65],
      female: [29, 33, 37, 41, 44, 47, 51, 55, 59]
    },
    junior: {
      age_min: 15, age_max: 17,
      male: [45, 48, 51, 55, 59, 63, 68, 73, 78],
      female: [42, 44, 46, 49, 52, 55, 59, 63, 68]
    },
    senior_world: {
      age_min: 17, age_max: nil,
      male: [54, 58, 63, 68, 74, 80, 87],
      female: [46, 49, 53, 57, 62, 67, 73]
    },
    senior_olympic: {
      age_min: 17, age_max: nil,
      male: [58, 68, 80],
      female: [49, 57, 67]
    }
  }.freeze

  INDIVIDUAL_POOMSAE_AGE_DIVISIONS = [
    { key: "under-9", age_min: nil, age_max: 9 },
    { key: "under-11", age_min: 10, age_max: 11 },
    { key: "cadet", age_min: 12, age_max: 14 },
    { key: "junior", age_min: 15, age_max: 17 },
    { key: "under-30", age_min: 18, age_max: 30 },
    { key: "under-40", age_min: 31, age_max: 40 },
    { key: "under-50", age_min: 41, age_max: 50 },
    { key: "under-60", age_min: 51, age_max: 60 },
    { key: "under-65", age_min: 61, age_max: 65 },
    { key: "over-65", age_min: 66, age_max: nil }
  ].freeze

  # Pair (1 male + 1 female) and mixed-team poomsae use two broad age tiers
  # rather than the finer-grained individual-poomsae age divisions.
  PAIR_TEAM_POOMSAE_AGE_DIVISIONS = [
    { key: "under-17", age_min: 12, age_max: 17 },
    { key: "over-17", age_min: 18, age_max: nil }
  ].freeze

  def self.weight_brackets_for(boundaries)
    brackets = []
    previous_max = nil
    boundaries.each do |max|
      brackets << { weight_min: previous_max, weight_max: max }
      previous_max = max
    end
    brackets << { weight_min: previous_max, weight_max: nil }
    brackets
  end

  def self.weight_bracket_key(bracket)
    if bracket[:weight_min].nil?
      "u#{bracket[:weight_max]}"
    elsif bracket[:weight_max].nil?
      "o#{bracket[:weight_min]}"
    else
      "#{bracket[:weight_min]}-#{bracket[:weight_max]}"
    end
  end

  # NOTE: every hash below carries ALL of event_type/gender/age_min/age_max/
  # weight_min/weight_max explicitly (using nil rather than omitting a key)
  # because find_or_create_by! turns a nil value into "column IS NULL" but
  # turns an OMITTED key into "no constraint on that column at all" — with
  # some keys omitted, two different brackets that share every other field
  # (e.g. a Senior World bracket and the open-ended Senior Olympic bracket
  # above it) could silently match the same existing row instead of getting
  # their own.
  def self.build_kyorugi_templates
    KYORUGI_WEIGHT_BOUNDARIES.flat_map do |age_group, config|
      %i[male female].flat_map do |gender|
        weight_brackets_for(config.fetch(gender)).map do |bracket|
          {
            key: "kyorugi-#{age_group.to_s.dasherize}-#{gender}-#{weight_bracket_key(bracket)}",
            event_type: "kyorugi",
            gender: gender.to_s,
            age_min: config[:age_min],
            age_max: config[:age_max],
            weight_min: bracket[:weight_min],
            weight_max: bracket[:weight_max]
          }
        end
      end
    end
  end

  def self.build_individual_poomsae_templates
    INDIVIDUAL_POOMSAE_AGE_DIVISIONS.flat_map do |division|
      %w[male female].map do |gender|
        {
          key: "individual-poomsae-#{gender}-#{division[:key]}",
          event_type: "individual_poomsae",
          gender: gender,
          age_min: division[:age_min],
          age_max: division[:age_max]
        }
      end
    end
  end

  def self.build_pair_poomsae_templates
    PAIR_TEAM_POOMSAE_AGE_DIVISIONS.map do |division|
      {
        key: "pair-poomsae-#{division[:key]}",
        event_type: "pair_poomsae",
        gender: nil,
        age_min: division[:age_min],
        age_max: division[:age_max]
      }
    end
  end

  def self.build_team_poomsae_templates
    PAIR_TEAM_POOMSAE_AGE_DIVISIONS.map do |division|
      {
        key: "team-poomsae-#{division[:key]}",
        event_type: "team_poomsae",
        gender: nil,
        age_min: division[:age_min],
        age_max: division[:age_max]
      }
    end
  end

  DEFAULT_CATEGORY_TEMPLATES = (
    build_kyorugi_templates +
    build_individual_poomsae_templates +
    build_pair_poomsae_templates +
    build_team_poomsae_templates
  ).freeze

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
