class SuperAdminNotification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true

  enum :kind, {
    academy_submission: 0,
    unregistered_academy_athlete: 1,
    tournament_submission: 2
  }
  enum :status, { pending: 0, approved: 1, rejected: 2, reviewed: 3, dismissed: 4 }

  scope :active, -> { pending.where(dismissed_at: nil) }
  scope :latest_first, -> { order(created_at: :desc, id: :desc) }

  validates :kind, :status, presence: true

  def self.notify!(kind:, notifiable:, actor: nil, message: nil)
    notification = pending.find_or_initialize_by(kind: kind, notifiable: notifiable)
    notification.actor = actor if actor.present?
    notification.message = message
    notification.dismissed_at = nil
    notification.save!
    notification
  end

  def title
    case kind
    when "academy_submission" then "Academy approval needed"
    when "unregistered_academy_athlete" then "Unregistered academy review"
    when "tournament_submission" then "New tournament created"
    else kind.humanize
    end
  end

  def approve!(reviewer:)
    transaction do
      approve_notifiable!(reviewer)
      update!(status: approval_status, reviewed_by: reviewer, reviewed_at: Time.current)
    end
  end

  def reject!(reviewer:)
    transaction do
      reject_notifiable!(reviewer)
      update!(status: :rejected, reviewed_by: reviewer, reviewed_at: Time.current)
    end
  end

  def dismiss!
    update!(status: :dismissed, dismissed_at: Time.current)
  end

  private

  def approve_notifiable!(reviewer)
    case kind
    when "academy_submission"
      academy = notifiable
      academy.update!(status: :approved, reviewed_at: Time.current, rejection_reason: nil)
      academy.owner&.academy_owner!
    end
  end

  def reject_notifiable!(reviewer)
    case kind
    when "academy_submission"
      notifiable.update!(status: :rejected, reviewed_at: Time.current, rejection_reason: "Rejected by super admin.")
    when "unregistered_academy_athlete"
      notifiable.update!(external_academy_name: nil)
    end
  end

  def approval_status
    tournament_submission? ? :reviewed : :approved
  end
end
