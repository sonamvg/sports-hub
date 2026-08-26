class User < ApplicationRecord
  has_secure_password
  has_many :athletes, dependent: :destroy
  has_many :owned_academies, class_name: "Academy", foreign_key: :owner_id, dependent: :nullify
  has_many :organized_tournaments, class_name: "Tournament", foreign_key: :organizer_id, dependent: :restrict_with_error
  has_many :tournament_organizers, dependent: :destroy
  has_many :collaborating_tournaments, through: :tournament_organizers, source: :tournament
  belongs_to :organizer_reviewed_by, class_name: "User", optional: true
  belongs_to :organizer_academy, class_name: "Academy", optional: true
  has_one_attached :identity_document

  enum :role, { parent: 0, athlete: 1, coach: 2, organizer: 3, super_admin: 4, academy_owner: 5 }, default: :parent
  enum :organizer_status, { verified: 0, pending: 1, rejected: 2 }, prefix: :organizer

  before_validation :normalize_email
  before_validation :normalize_profile_photo_url
  before_validation :normalize_organizer_profile_fields

  validates :name, :email, presence: true
  validates :email, uniqueness: true
  validates :profile_photo_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid http or https URL" }, allow_blank: true
  validates :phone, presence: true, if: :organizer_registration_pending?
  validates :organizer_designation, presence: true, if: :organizer_registration_pending?
  validate :identity_document_required_for_pending_organizer

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

  private

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
end
