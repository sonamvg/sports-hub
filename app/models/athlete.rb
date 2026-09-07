class Athlete < ApplicationRecord
  include ConsentRecordable
  include AttachmentContentTypeValidatable

  attr_accessor :account_email

  GENDERS = %w[female male].freeze
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
  # Lets an athlete upload both sides of an Aadhaar card, or multiple passport
  # pages, instead of being limited to a single government ID file.
  MAX_IDENTITY_DOCUMENTS = 5

  belongs_to :user
  belongs_to :academy, optional: true
  has_many :registrations, dependent: :destroy
  has_many :academy_membership_requests, dependent: :destroy
  has_one_attached :profile_photo
  has_many_attached :identity_documents

  before_validation :normalize_profile_fields

  validates :first_name, :last_name, :date_of_birth, :gender, presence: true
  validates :first_name, :last_name, length: { in: 2..60 }, allow_blank: true
  validates :gender, inclusion: { in: GENDERS }, allow_blank: true
  validates :belt, inclusion: { in: BELTS }, allow_blank: true
  validates :blood_group, inclusion: { in: BLOOD_GROUPS }, allow_blank: true
  validates :government_id_document_type, inclusion: { in: GOVERNMENT_ID_DOCUMENT_TYPES }, allow_blank: true
  validates :weight, numericality: { greater_than: 0, less_than_or_equal_to: 999.99 }, allow_nil: true
  validates :city, format: { with: User::NAME_FORMAT, message: "can only contain letters, spaces, hyphens, and apostrophes" }, length: { maximum: 60 }, allow_blank: true
  validates :state, inclusion: { in: Tournament::INDIAN_STATES_AND_UNION_TERRITORIES }, allow_blank: true
  validates :address, length: { maximum: 255 }, allow_blank: true
  validates :emergency_contact_name, format: { with: User::NAME_FORMAT, message: "can only contain letters, spaces, hyphens, and apostrophes" }, allow_blank: true
  validates :profile_photo_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid http or https URL" }, allow_blank: true
  validate :profile_photo_size
  validate :identity_documents_size
  validate :identity_documents_count
  validate :academy_must_be_approved
  validate :date_of_birth_cannot_be_in_the_future
  validate :emergency_contact_must_differ_from_athlete

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  def academy_display_name
    academy&.name || external_academy_name
  end

  def pending_academy_request
    academy_membership_requests.pending.includes(:academy).order(created_at: :desc).first
  end

  def profile_complete_for_registration?
    contact_number.present?
  end

  # Prefers an uploaded photo (already validated for size/type) and falls
  # back to the optional external URL when no file has been uploaded.
  def profile_photo_source
    return profile_photo if profile_photo.attached?

    profile_photo_url.presence
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
    self.profile_photo_url = profile_photo_url.to_s.squish.presence
  end

  def date_of_birth_cannot_be_in_the_future
    return if date_of_birth.blank? || date_of_birth <= Date.current

    errors.add(:date_of_birth, "cannot be in the future")
  end

  def academy_must_be_approved
    return if academy.blank? || academy.approved?

    errors.add(:academy, "must be approved before athletes can be assigned")
  end

  def emergency_contact_must_differ_from_athlete
    if emergency_contact_name.present? && full_name.present? && emergency_contact_name.casecmp?(full_name)
      errors.add(:emergency_contact_name, "cannot be the same as the athlete's own name")
    end

    if emergency_contact_phone.present? && contact_number.present? && emergency_contact_phone == contact_number
      errors.add(:emergency_contact_phone, "cannot be the same as the athlete's own contact number")
    end
  end

  def profile_photo_size
    validate_upload_size(profile_photo, :profile_photo)
  end

  def identity_documents_size
    identity_documents.each { |document| validate_upload_size(document, :identity_documents) }
  end

  def identity_documents_count
    return if identity_documents.size <= MAX_IDENTITY_DOCUMENTS

    errors.add(:identity_documents, "cannot include more than #{MAX_IDENTITY_DOCUMENTS} files")
  end

  def validate_upload_size(attachment, attribute)
    return if attachment.respond_to?(:attached?) && !attachment.attached?

    if attachment.blob.byte_size < MIN_UPLOAD_SIZE
      errors.add(attribute, "must be at least 1 byte")
    elsif attachment.blob.byte_size > MAX_UPLOAD_SIZE
      errors.add(attribute, "must be 5 MB or smaller")
    end

    return if attachment_content_type_allowed?(attachment, ACCEPTED_UPLOAD_TYPES)

    errors.add(attribute, "must be a JPG or PNG file")
  end
end
