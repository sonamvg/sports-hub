class TournamentOrganizerInvitation < ApplicationRecord
  belongs_to :tournament
  belongs_to :invited_by, class_name: "User"

  enum :status, { pending: 0, accepted: 1, cancelled: 2 }, default: :pending

  before_validation :normalize_email

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :tournament_id }
  validate :email_is_not_existing_verified_organizer

  private

  def normalize_email
    self.email = email.to_s.downcase.squish.presence
  end

  def email_is_not_existing_verified_organizer
    return if email.blank?
    return unless User.verified_organizers.exists?(email: email)

    errors.add(:email, "already belongs to a verified organiser")
  end
end
