class Tournament < ApplicationRecord
  include ConsentRecordable

  MAX_IMAGE_SIZE = 5.megabytes
  ACCEPTED_IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze

  before_validation :normalize_fields

  belongs_to :organizer, class_name: "User"
  has_many :tournament_categories, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :tournament_organizers, dependent: :destroy
  has_many :organizer_users, through: :tournament_organizers, source: :user
  has_many :tournament_organizer_invitations, dependent: :destroy
  has_many :tournament_referees, dependent: :destroy
  has_one_attached :logo_image
  has_one_attached :banner_image

  DEFAULT_COMPETITION_FORMATS = [
    "Kyorugi",
    "Individual Poomsae",
    "Team Poomsae"
  ].freeze

  DEFAULT_ELIGIBILITY_RULES = [
    "Age proof required",
    "Valid academy or association membership",
    "Medical fitness declaration",
    "Minimum belt requirement",
    "Guardian consent for minors"
  ].freeze

  DEFAULT_REQUIRED_DOCUMENTS = [
    "Age proof",
    "Government identity proof",
    "Academy approval letter",
    "Association ID",
    "Medical clearance"
  ].freeze

  DEFAULT_REFUND_POLICIES = [
    "Full refund before registration closes",
    "Partial refund after registration closes",
    "No refund after final schedules are published",
    "Refund only if event is cancelled",
    "Transfer registration to another athlete is not allowed"
  ].freeze

  enum :status, {
    draft: 0,
    registration_open: 1,
    registration_closed: 2,
    in_progress: 3,
    completed: 4,
    cancelled: 5,
    ready_for_review: 6,
    scheduled: 7,
    registration_paused: 8,
    archived: 10
  }, default: :draft

  validates :name, :start_date, :end_date, presence: true
  validates :name, length: { minimum: 3, maximum: 120 }, allow_blank: true
  validates :slug, uniqueness: true, allow_blank: true
  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid http or https URL" }, allow_blank: true
  validates :primary_contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :registration_capacity, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
  validates :registration_fee, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :courts_count, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
  validate :end_date_not_before_start_date
  validate :registration_window_chronology
  validate :logo_image_size
  validate :banner_image_size

  after_create :add_creator_as_super_organizer

  def accepting_registrations?(at: Time.current)
    registration_open? &&
      (registration_opens_at.blank? || registration_opens_at <= at) &&
      (registration_closes_at.blank? || registration_closes_at >= at)
  end

  def registration_closed_for_weight_check?(at: Time.current)
    registration_closes_at.present? && registration_closes_at < at
  end

  def late_registration_allowed_for?(user)
    return false unless user
    user.super_admin? || tournament_organizers.super_organizer.exists?(user_id: user.id)
  end

  def managed_by?(user)
    return false unless user

    organizer_id == user.id || tournament_organizers.exists?(user_id: user.id)
  end

  def logo_image_source
    logo_image if logo_image.attached?
  end

  def banner_image_source
    banner_image if banner_image.attached?
  end

  private

  def normalize_fields
    self.name = name.to_s.squish.presence
    self.slug = slug.presence
    self.website_url = website_url.to_s.squish.presence
    self.city = city.to_s.squish.presence
    self.state = state.to_s.squish.presence
    self.country = country.to_s.squish.presence || "India"
    self.tournament_level = tournament_level.to_s.squish.presence
    self.organizing_organization = organizing_organization.to_s.squish.presence
    self.time_zone = time_zone.to_s.squish.presence
    self.primary_contact_name = primary_contact_name.to_s.squish.presence
    self.primary_contact_email = primary_contact_email.to_s.downcase.squish.presence
    self.primary_contact_phone = primary_contact_phone.to_s.squish.presence
    self.competition_formats = competition_formats.to_s.squish.presence
    self.eligibility_summary = eligibility_summary.to_s.squish.presence
    self.category_generation_method = category_generation_method.to_s.squish.presence
    self.currency = currency.to_s.upcase.squish.presence
    self.required_documents = required_documents.to_s.squish.presence
    self.refund_policy = refund_policy.to_s.squish.presence
    self.payment_account_name = payment_account_name.to_s.squish.presence
    self.payment_bank_name = payment_bank_name.to_s.squish.presence
    self.payment_account_number = payment_account_number.to_s.squish.presence
    self.payment_ifsc = payment_ifsc.to_s.upcase.squish.presence
    self.payment_instructions = payment_instructions.to_s.squish.presence
  end

  def end_date_not_before_start_date
    return if start_date.blank? || end_date.blank?
    errors.add(:end_date, "cannot be before start date") if end_date < start_date
  end

  def registration_window_chronology
    if registration_opens_at.present? && registration_closes_at.present? && registration_opens_at >= registration_closes_at
      errors.add(:registration_closes_at, "must be after registration opens at")
    end

    if registration_closes_at.present? && start_date.present? && registration_closes_at.to_date > start_date
      errors.add(:registration_closes_at, "cannot be after the event start date")
    end
  end

  def add_creator_as_super_organizer
    tournament_organizers.find_or_create_by!(user: organizer) do |membership|
      membership.role = :super_organizer
      membership.added_by = organizer
    end
  end

  def logo_image_size
    validate_image_upload(logo_image, :logo_image)
  end

  def banner_image_size
    validate_image_upload(banner_image, :banner_image)
  end

  def validate_image_upload(attachment, attribute)
    return unless attachment.attached?

    errors.add(attribute, "must be 5 MB or smaller") if attachment.blob.byte_size > MAX_IMAGE_SIZE
    errors.add(attribute, "must be a JPG, PNG, or WebP file") unless attachment.blob.content_type.in?(ACCEPTED_IMAGE_TYPES)
  end
end
