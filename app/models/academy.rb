class Academy < ApplicationRecord
  MAX_LOGO_IMAGE_SIZE = 5.megabytes

  belongs_to :owner, class_name: "User", optional: true
  has_many :athletes, dependent: :nullify
  has_many :academy_membership_requests, dependent: :destroy
  has_one_attached :logo_image

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :name, :city, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :logo_image_size

  def visible_to_public?
    approved?
  end

  private

  def logo_image_size
    return unless logo_image.attached?

    errors.add(:logo_image, "must be 5 MB or smaller") if logo_image.blob.byte_size > MAX_LOGO_IMAGE_SIZE
  end
end
