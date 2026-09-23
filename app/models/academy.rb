class Academy < ApplicationRecord
  include ConsentRecordable
  include AttachmentContentTypeValidatable
  include EmailFormatValidatable

  MAX_LOGO_IMAGE_SIZE = 5.megabytes
  ACCEPTED_LOGO_IMAGE_TYPES = %w[image/jpeg image/png].freeze
  # At least one letter, plus letters/digits/spaces/hyphens/apostrophes only —
  # blocks a name or place that's blank-looking (all spaces) or all digits.
  NAME_OR_PLACE_FORMAT = /\A(?=.*[a-zA-Z])[a-zA-Z0-9\s'-]+\z/

  belongs_to :owner, class_name: "User", optional: true
  has_many :athletes, dependent: :nullify
  has_many :academy_membership_requests, dependent: :destroy
  has_many :super_admin_notifications, as: :notifiable, dependent: :destroy
  has_one_attached :logo_image

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :name, :city, presence: true
  validates :name, uniqueness: { scope: :city, case_sensitive: false, message: "already exists in this city" }, allow_blank: true
  validates :name, format: { with: NAME_OR_PLACE_FORMAT, message: "must contain letters, and can include spaces, numbers, hyphens, and apostrophes" }, allow_blank: true
  validates :name, length: { maximum: 120 }, allow_blank: true
  validates :city, :state, :country, format: { with: NAME_OR_PLACE_FORMAT, message: "cannot be blank or numbers only" }, allow_blank: true
  validates :city, :state, :country, length: { maximum: 60 }, allow_blank: true
  validates :contact_name, format: { with: User::NAME_FORMAT, message: "can only contain letters, spaces, hyphens, and apostrophes" }, allow_blank: true
  validates :phone, format: { with: User::PHONE_FORMAT, message: "must be a 10-digit mobile number" }, allow_blank: true
  validates :pincode, format: { with: IndianLocation::PINCODE_FORMAT, message: "must be a valid 6-digit PIN code" }, allow_blank: true
  validates :registration_number, length: { maximum: 60 }, allow_blank: true
  validates :email, format: { with: EmailFormatValidatable::STRICT_EMAIL_REGEXP }, allow_blank: true
  rejects_placeholder_email :email
  validate :logo_image_size

  def visible_to_public?
    approved?
  end

  # A full, restorable dump of every academy for a super admin backup/export
  # — every column plus the owner's name/email for a human-readable link,
  # since owner_id alone means nothing outside this database.
  def self.to_export_csv
    columns = %w[
      id name registration_number status city state country pincode
      contact_name phone email owner_id owner_name owner_email
      terms_accepted_at data_sharing_consent_accepted_at reviewed_at
      rejection_reason created_at updated_at
    ]

    CSV.generate(headers: true) do |csv|
      csv << columns
      includes(:owner).find_each do |academy|
        csv << [
          academy.id, academy.name, academy.registration_number, academy.status,
          academy.city, academy.state, academy.country, academy.pincode,
          academy.contact_name, academy.phone, academy.email,
          academy.owner_id, academy.owner&.name, academy.owner&.email,
          academy.terms_accepted_at, academy.data_sharing_consent_accepted_at,
          academy.reviewed_at, academy.rejection_reason,
          academy.created_at, academy.updated_at
        ]
      end
    end
  end

  private

  def logo_image_size
    return unless logo_image.attached?

    errors.add(:logo_image, "file size should be less than 5 MB and PNG/JPG is accepted") if logo_image.blob.byte_size > MAX_LOGO_IMAGE_SIZE
    errors.add(:logo_image, "file size should be less than 5 MB and PNG/JPG is accepted") unless attachment_content_type_allowed?(logo_image, ACCEPTED_LOGO_IMAGE_TYPES)
  end

end
