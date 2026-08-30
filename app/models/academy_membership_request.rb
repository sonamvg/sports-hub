class AcademyMembershipRequest < ApplicationRecord
  belongs_to :academy
  belongs_to :athlete
  belongs_to :requested_by, class_name: "User"
  belongs_to :reviewed_by, class_name: "User", optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  scope :active_notifications, -> { where(dismissed_at: nil) }

  validates :academy_id, uniqueness: { scope: [:athlete_id, :status], conditions: -> { pending }, message: "already has a pending request for this athlete" }, if: :pending?

  def approve!(reviewer:)
    transaction do
      athlete.update!(academy: academy, external_academy_name: nil)
      update!(status: :approved, reviewed_by: reviewer, reviewed_at: Time.current)
    end
  end

  def reject!(reviewer:)
    update!(status: :rejected, reviewed_by: reviewer, reviewed_at: Time.current)
  end

  def dismiss!
    update!(dismissed_at: Time.current)
  end
end
