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
  has_one_attached :logo_image

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :name, :city, presence: true
  validates :name, uniqueness: { scope: :city, case_sensitive: false, message: "already exists in this city" }, allow_blank: true
  validates :name, format: { with: NAME_OR_PLACE_FORMAT, message: "must contain letters, and can include spaces, numbers, hyphens, and apostrophes" }, allow_blank: true
  validates :city, format: { with: NAME_OR_PLACE_FORMAT, message: "cannot be blank or numbers only" }, allow_blank: true
  validates :state, format: { with: NAME_OR_PLACE_FORMAT, message: "cannot be blank or numbers only" }, allow_blank: true
  validates :country, format: { with: NAME_OR_PLACE_FORMAT, message: "cannot be blank or numbers only" }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  rejects_placeholder_email :email
  validate :logo_image_size

  def visible_to_public?
    approved?
  end

  private

  def logo_image_size
    return unless logo_image.attached?

    errors.add(:logo_image, "file size should be less than 5 MB and PNG/JPG is accepted") if logo_image.blob.byte_size > MAX_LOGO_IMAGE_SIZE
    errors.add(:logo_image, "file size should be less than 5 MB and PNG/JPG is accepted") unless attachment_content_type_allowed?(logo_image, ACCEPTED_LOGO_IMAGE_TYPES)
  end

end
