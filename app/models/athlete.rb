class Athlete < ApplicationRecord
  attr_accessor :account_email

  GENDERS = %w[female male other].freeze
  BELTS = %w[white yellow green blue red black].freeze
  BLOOD_GROUPS = %w[A+ A- B+ B- AB+ AB- O+ O-].freeze
  GOVERNMENT_ID_DOCUMENT_TYPES = [
    "Aadhaar",
    "Passport",
    "Voter ID",
    "Driving licence",
    "School ID",
    "Other government ID"
  ].freeze
  MIN_UPLOAD_SIZE = 1.byte
  MAX_UPLOAD_SIZE = 5.megabytes
  ACCEPTED_UPLOAD_TYPES = %w[image/jpeg image/png].freeze

  belongs_to :user
  belongs_to :academy, optional: true
  has_many :registrations, dependent: :destroy
  has_many :academy_membership_requests, dependent: :destroy
  has_one_attached :profile_photo
  has_one_attached :identity_document

  before_validation :normalize_profile_fields

  validates :first_name, :last_name, :date_of_birth, :gender, presence: true
  validates :first_name, :last_name, length: { in: 2..60 }, allow_blank: true
  validates :gender, inclusion: { in: GENDERS }, allow_blank: true
  validates :belt, inclusion: { in: BELTS }, allow_blank: true
  validates :blood_group, inclusion: { in: BLOOD_GROUPS }, allow_blank: true
  validates :government_id_document_type, inclusion: { in: GOVERNMENT_ID_DOCUMENT_TYPES }, allow_blank: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true
  validate :profile_photo_size
  validate :identity_document_size
  validate :academy_must_be_approved
  validate :date_of_birth_cannot_be_in_the_future

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  def academy_display_name
    academy&.name || external_academy_name
  end

  def pending_academy_request
    academy_membership_requests.pending.includes(:academy).order(created_at: :desc).first
  end

  private

  def normalize_profile_fields
    self.first_name = first_name.to_s.squish.presence
    self.last_name = last_name.to_s.squish.presence
    self.gender = gender.to_s.downcase.presence
    self.belt = belt.to_s.downcase.presence
    self.association_id = association_id.to_s.squish.presence
    self.external_academy_name = external_academy_name.to_s.squish.presence
    self.city = city.to_s.squish.presence
    self.state = state.to_s.squish.presence
    self.country = country.to_s.squish.presence || "India"
    self.contact_number = contact_number.to_s.squish.presence
    self.blood_group = blood_group.to_s.squish.upcase.presence
    self.emergency_contact_name = emergency_contact_name.to_s.squish.presence
    self.emergency_contact_phone = emergency_contact_phone.to_s.squish.presence
    self.address = address.to_s.squish.presence
    self.government_id_document_type = government_id_document_type.to_s.squish.presence
  end

  def date_of_birth_cannot_be_in_the_future
    return if date_of_birth.blank? || date_of_birth <= Date.current

    errors.add(:date_of_birth, "cannot be in the future")
  end

  def academy_must_be_approved
    return if academy.blank? || academy.approved?

    errors.add(:academy, "must be approved before athletes can be assigned")
  end

  def profile_photo_size
    validate_upload_size(profile_photo, :profile_photo)
  end

  def identity_document_size
    validate_upload_size(identity_document, :identity_document)
  end

  def validate_upload_size(attachment, attribute)
    return unless attachment.attached?

    if attachment.blob.byte_size < MIN_UPLOAD_SIZE
      errors.add(attribute, "must be at least 1 byte")
    elsif attachment.blob.byte_size > MAX_UPLOAD_SIZE
      errors.add(attribute, "must be 5 MB or smaller")
    end

    return if attachment.blob.content_type.in?(ACCEPTED_UPLOAD_TYPES)

    errors.add(attribute, "must be a JPG or PNG file")
  end
end
