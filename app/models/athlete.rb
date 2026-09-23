class Athlete < ApplicationRecord
  include ConsentRecordable
  include AttachmentContentTypeValidatable

  attr_accessor :account_email
  # Set by the controller when an academy owner adds an athlete to their own
  # (not-yet-approved) academy — internal roster management shouldn't wait
  # on admin approval, which only gates the academy's public visibility.
  attr_accessor :skip_academy_approval_check

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
  MAX_AGE_YEARS = 100

  belongs_to :user
  belongs_to :academy, optional: true
  has_many :registrations, dependent: :destroy
  has_many :academy_membership_requests, dependent: :destroy
  has_many :super_admin_notifications, as: :notifiable, dependent: :destroy
  has_one_attached :profile_photo
  has_many_attached :identity_documents

  before_validation :normalize_profile_fields

  validates :first_name, :last_name, :date_of_birth, :gender, presence: true
  validates :first_name, :last_name, :middle_name, length: { in: 2..60 }, allow_blank: true
  validates :first_name, :last_name, :middle_name, format: { with: User::NAME_FORMAT, message: "can only contain letters, spaces, hyphens, and apostrophes" }, allow_blank: true
  validates :gender, inclusion: { in: GENDERS }, allow_blank: true
  validates :belt, inclusion: { in: BELTS }, allow_blank: true
  validates :blood_group, inclusion: { in: BLOOD_GROUPS }, allow_blank: true
  validates :government_id_document_type, inclusion: { in: GOVERNMENT_ID_DOCUMENT_TYPES }, allow_blank: true
  validates :weight, numericality: { greater_than: 0, less_than_or_equal_to: 999.99 }, allow_nil: true
  validates :city, format: { with: User::NAME_FORMAT, message: "can only contain letters, spaces, hyphens, and apostrophes" }, length: { maximum: 60 }, allow_blank: true
  validates :state, inclusion: { in: Tournament::INDIAN_STATES_AND_UNION_TERRITORIES }, allow_blank: true
  validates :pincode, format: { with: IndianLocation::PINCODE_FORMAT, message: "must be a valid 6-digit PIN code" }, allow_blank: true
  validates :address, length: { maximum: 255 }, allow_blank: true
  validates :emergency_contact_name, format: { with: User::NAME_FORMAT, message: "can only contain letters, spaces, hyphens, and apostrophes" }, allow_blank: true
  validates :contact_number, format: { with: User::PHONE_FORMAT, message: "must be a 10-digit mobile number" }, allow_blank: true
  validates :emergency_contact_phone, format: { with: User::PHONE_FORMAT, message: "must be a 10-digit mobile number" }, allow_blank: true
  validates :profile_photo_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid http or https URL" }, allow_blank: true
  validate :profile_photo_size
  validate :identity_documents_size
  validate :identity_documents_count
  validate :academy_must_be_approved
  validate :date_of_birth_cannot_be_in_the_future
  validate :emergency_contact_must_differ_from_athlete

  def full_name
    [first_name, middle_name, last_name].compact_blank.join(" ")
  end

  # A full, restorable dump of every athlete for a super admin backup/export
  # — every column plus the parent account's/academy's name for a
  # human-readable link, since user_id/academy_id alone mean nothing outside
  # this database.
  def self.to_export_csv
    columns = %w[
      id first_name middle_name last_name gender date_of_birth weight belt
      blood_group association_id contact_number address city state country
      pincode emergency_contact_name emergency_contact_phone
      government_id_document_type academy_id academy_name external_academy_name
      user_id user_name user_email terms_accepted_at
      data_sharing_consent_accepted_at created_at updated_at
    ]

    CSV.generate(headers: true) do |csv|
      csv << columns
      includes(:academy, :user).find_each do |athlete|
        csv << [
          athlete.id, athlete.first_name, athlete.middle_name, athlete.last_name,
          athlete.gender, athlete.date_of_birth, athlete.weight, athlete.belt,
          athlete.blood_group, athlete.association_id, athlete.contact_number,
          athlete.address, athlete.city, athlete.state, athlete.country, athlete.pincode,
          athlete.emergency_contact_name, athlete.emergency_contact_phone,
          athlete.government_id_document_type, athlete.academy_id, athlete.academy&.name,
          athlete.external_academy_name, athlete.user_id, athlete.user&.name, athlete.user&.email,
          athlete.terms_accepted_at, athlete.data_sharing_consent_accepted_at,
          athlete.created_at, athlete.updated_at
        ]
      end
    end
  end

  def age
    return if date_of_birth.blank?

    today = Date.current
    years = today.year - date_of_birth.year
    years -= 1 if today < date_of_birth + years.years
    years
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

  # True once this athlete has been placed into at least one Match (a draw
  # sheet slot, a result, or an opponent's own result) — those Match rows,
  # and any opponent's history, reference this athlete's registrations by
  # id with no cascade, so the registrations (and this athlete) can't be
  # hard-deleted without breaking that history.
  def has_match_history?
    registration_ids = registrations.select(:id)
    Match.where(registration_one_id: registration_ids)
      .or(Match.where(registration_two_id: registration_ids))
      .or(Match.where(winner_registration_id: registration_ids))
      .exists?
  end

  # Used instead of a hard delete when #has_match_history? — clears personal
  # contact details, documents, and the academy link, but leaves the name
  # (and registrations) in place so draw sheets and past opponents keep
  # showing who they fought. Mirrors User#deactivate!'s "keep the name,
  # clear everything else" approach for organizer accounts.
  def anonymize!
    academy_membership_requests.pending.update_all(status: AcademyMembershipRequest.statuses[:rejected], reviewed_at: Time.current, updated_at: Time.current)

    update_columns(
      academy_id: nil,
      external_academy_name: nil,
      association_id: nil,
      weight: nil,
      blood_group: nil,
      contact_number: nil,
      address: nil,
      city: nil,
      state: nil,
      pincode: nil,
      emergency_contact_name: nil,
      emergency_contact_phone: nil,
      government_id_document_type: nil,
      profile_photo_url: nil
    )
    profile_photo.purge_later if profile_photo.attached?
    identity_documents.purge_later if identity_documents.attached?
  end

  # Removes this athlete profile: destroyed outright when there's no match
  # history to preserve, otherwise #anonymize!d instead. Returns true when
  # actually destroyed, false when anonymized instead, so callers can show
  # the right message.
  def delete_or_anonymize!
    if has_match_history?
      anonymize!
      false
    else
      destroy!
      true
    end
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
    self.middle_name = middle_name.to_s.squish.presence
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
    return if date_of_birth.blank?
    return errors.add(:date_of_birth, "cannot be in the future") if date_of_birth > Date.current
    return if date_of_birth >= MAX_AGE_YEARS.years.ago.to_date

    errors.add(:date_of_birth, "must indicate an age of #{MAX_AGE_YEARS} years or less")
  end

  def academy_must_be_approved
    return if academy.blank? || academy.approved? || skip_academy_approval_check

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
