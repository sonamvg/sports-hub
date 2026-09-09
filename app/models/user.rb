class User < ApplicationRecord
  include AttachmentContentTypeValidatable
  include EmailFormatValidatable

  MAX_IDENTITY_DOCUMENT_SIZE = 5.megabytes
  ACCEPTED_IDENTITY_DOCUMENT_TYPES = %w[image/jpeg image/png application/pdf].freeze
  MAX_PROFILE_PHOTO_SIZE = 5.megabytes
  ACCEPTED_PROFILE_PHOTO_TYPES = %w[image/jpeg image/png].freeze

  has_secure_password
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  has_many :athletes, dependent: :destroy
  has_many :owned_academies, class_name: "Academy", foreign_key: :owner_id, dependent: :nullify
  has_many :organized_tournaments, class_name: "Tournament", foreign_key: :organizer_id, dependent: :restrict_with_error
  has_many :tournament_organizers, dependent: :destroy
  has_many :collaborating_tournaments, through: :tournament_organizers, source: :tournament
  belongs_to :organizer_reviewed_by, class_name: "User", optional: true
  has_one_attached :identity_document
  has_one_attached :profile_photo

  enum :role, { parent: 0, athlete: 1, coach: 2, organizer: 3, super_admin: 4, academy_owner: 5 }, default: :parent
  enum :organizer_status, { verified: 0, pending: 1, rejected: 2 }, prefix: :organizer

  NAME_FORMAT = /\A[a-zA-Z]+(?:[\s'-][a-zA-Z]+)*\z/
  PHONE_FORMAT = /\A\d{10}\z/
  PASSWORD_FORMAT = /\A(?=.*[A-Za-z])(?=.*[0-9])\S+\z/

  before_validation :normalize_name
  before_validation :normalize_email
  before_validation :normalize_profile_photo_url
  before_validation :normalize_organizer_profile_fields

  validates :name, :email, presence: true
  validates :name, format: { with: NAME_FORMAT, message: "can only contain letters, spaces, hyphens, and apostrophes" }, allow_blank: true
  validates :email, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }, allow_blank: true
  rejects_placeholder_email :email
  validates :profile_photo_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid http or https URL" }, allow_blank: true
  validates :phone, presence: true, if: :organizer_registration_pending?
  validates :phone, format: { with: PHONE_FORMAT, message: "must be a 10-digit mobile number" }, allow_blank: true
  validates :organizer_designation, presence: true, if: :organizer_registration_pending?
  validates :password, length: { minimum: 8, maximum: 72 }, allow_blank: true
  validates :password, format: { with: PASSWORD_FORMAT, message: "must include at least one letter and one number, with no spaces" }, allow_blank: true
  validate :identity_document_required_for_pending_organizer
  validate :identity_document_size
  validate :profile_photo_size

  scope :verified_organizers, -> { organizer.organizer_verified }
  scope :pending_organizers, -> { organizer.organizer_pending }

  def admin?
    super_admin?
  end

  def can_organize_tournaments?
    super_admin? || academy_owner? || (organizer? && organizer_verified?)
  end

  def verify_organizer!(reviewer:)
    update!(organizer_status: :verified, organizer_approved_at: Time.current, organizer_rejected_at: nil, organizer_reviewed_by: reviewer)
  end

  def reject_organizer!(reviewer:)
    update!(organizer_status: :rejected, organizer_rejected_at: Time.current, organizer_reviewed_by: reviewer)
  end

  def organizer_event_names
    (organized_tournaments.to_a + collaborating_tournaments.to_a).uniq(&:id).sort_by(&:start_date).map(&:name)
  end

  def initials
    name.to_s.split.map { |part| part.first }.compact.first(2).join.upcase.presence || "OR"
  end

  def send_password_reset_email
    PasswordMailer.with(user: self).reset_instructions.deliver_later
  end

  # Prefers an uploaded photo (already validated for size/type) and falls
  # back to the optional external URL when no file has been uploaded.
  def profile_photo_source
    return profile_photo if profile_photo.attached?

    profile_photo_url.presence
  end

  private

  def normalize_name
    self.name = name.to_s.squish.presence
  end

  def normalize_email
    self.email = email.to_s.downcase.squish.presence
  end

  def normalize_profile_photo_url
    self.profile_photo_url = profile_photo_url.to_s.squish.presence
  end

  def normalize_organizer_profile_fields
    self.phone = phone.to_s.squish.presence
    self.organizer_designation = organizer_designation.to_s.squish.presence
  end

  def organizer_registration_pending?
    organizer? && organizer_pending?
  end

  def identity_document_required_for_pending_organizer
    return unless organizer_registration_pending?
    return if identity_document.attached?

    errors.add(:identity_document, "must be uploaded")
  end

  def identity_document_size
    return unless identity_document.attached?

    errors.add(:identity_document, "must be 5 MB or smaller") if identity_document.blob.byte_size > MAX_IDENTITY_DOCUMENT_SIZE
    errors.add(:identity_document, "must be a JPG, PNG, or PDF file") unless attachment_content_type_allowed?(identity_document, ACCEPTED_IDENTITY_DOCUMENT_TYPES)
  end

  def profile_photo_size
    return unless profile_photo.attached?

    errors.add(:profile_photo, "must be 5 MB or smaller") if profile_photo.blob.byte_size > MAX_PROFILE_PHOTO_SIZE
    errors.add(:profile_photo, "must be a JPG or PNG file") unless attachment_content_type_allowed?(profile_photo, ACCEPTED_PROFILE_PHOTO_TYPES)
  end
end
