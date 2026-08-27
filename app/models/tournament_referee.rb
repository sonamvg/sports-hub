class TournamentReferee < ApplicationRecord
  MIN_UPLOAD_SIZE = 1.byte
  MAX_UPLOAD_SIZE = 5.megabytes

  belongs_to :tournament
  has_one_attached :photo

  before_validation :normalize_fields

  validates :name, presence: true
  validates :name, length: { in: 2..100 }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :photo_size

  private

  def normalize_fields
    self.name = name.to_s.squish.presence
    self.email = email.to_s.downcase.squish.presence
    self.phone = phone.to_s.squish.presence
    self.role = role.to_s.squish.presence
    self.qualification = qualification.to_s.squish.presence
    self.certification_id = certification_id.to_s.squish.presence
    self.affiliation = affiliation.to_s.squish.presence
    self.notes = notes.to_s.squish.presence
  end

  def photo_size
    return unless photo.attached?

    if photo.blob.byte_size < MIN_UPLOAD_SIZE
      errors.add(:photo, "must be at least 1 byte")
    elsif photo.blob.byte_size > MAX_UPLOAD_SIZE
      errors.add(:photo, "must be 5 MB or smaller")
    end
  end
end
