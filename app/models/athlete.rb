class Athlete < ApplicationRecord
  GENDERS = %w[female male other].freeze
  BELTS = %w[white yellow green blue red black].freeze

  belongs_to :user
  belongs_to :academy, optional: true
  has_many :registrations, dependent: :destroy

  before_validation :normalize_profile_fields

  validates :first_name, :last_name, :date_of_birth, :gender, presence: true
  validates :first_name, :last_name, length: { in: 2..60 }, allow_blank: true
  validates :gender, inclusion: { in: GENDERS }, allow_blank: true
  validates :belt, inclusion: { in: BELTS }, allow_blank: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true
  validate :academy_must_be_approved
  validate :date_of_birth_cannot_be_in_the_future

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  private

  def normalize_profile_fields
    self.first_name = first_name.to_s.squish.presence
    self.last_name = last_name.to_s.squish.presence
    self.gender = gender.to_s.downcase.presence
    self.belt = belt.to_s.downcase.presence
    self.association_id = association_id.to_s.squish.presence
    self.city = city.to_s.squish.presence
    self.state = state.to_s.squish.presence
    self.country = country.to_s.squish.presence || "India"
  end

  def date_of_birth_cannot_be_in_the_future
    return if date_of_birth.blank? || date_of_birth <= Date.current

    errors.add(:date_of_birth, "cannot be in the future")
  end

  def academy_must_be_approved
    return if academy.blank? || academy.approved?

    errors.add(:academy, "must be approved before athletes can be assigned")
  end
end
