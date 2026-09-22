class RegistrationWeightCheck < ApplicationRecord
  belongs_to :registration
  belongs_to :checked_by, class_name: "User"

  before_validation :assign_attempt_number, :assign_passed, :assign_checked_at
  after_create :apply_registration_result

  validates :attempt_number, presence: true, inclusion: { in: 1..3 }
  validates :attempt_number, uniqueness: { scope: :registration_id }
  validates :weight, numericality: { greater_than: 0 }
  validate :registration_can_be_weighed
  validate :attempt_is_next_attempt
  validate :draw_not_yet_generated
  validate :tournament_not_closed_out

  private

  def assign_attempt_number
    self.attempt_number ||= registration&.next_weight_check_attempt_number
  end

  def assign_passed
    return if registration.blank? || weight.blank?

    self.passed = registration.weight_within_category?(weight)
  end

  def assign_checked_at
    self.checked_at ||= Time.current
  end

  def registration_can_be_weighed
    return if registration.blank?

    unless registration.approved?
      errors.add(:registration, "must be accepted before weight check")
    end
  end

  def draw_not_yet_generated
    return if registration.blank?

    if registration.tournament_category.draw_generated?
      errors.add(:base, "Weight check is locked because the draw has already been set")
    end
  end

  def tournament_not_closed_out
    return if registration.blank?

    if registration.tournament.closed_out?
      errors.add(:base, "Weight check is locked because the tournament has been #{registration.tournament.status}")
    end
  end

  def attempt_is_next_attempt
    return if registration.blank? || attempt_number.blank?

    if registration.registration_weight_checks.where.not(id: id).count >= 3
      errors.add(:base, "All weight check attempts are already used")
    elsif attempt_number != registration.next_weight_check_attempt_number
      errors.add(:attempt_number, "must be the next available attempt")
    end
  end

  # review! can fail without raising (e.g. the tournament closed out in the
  # instant between this record's own validation and this callback) — if it
  # does, abort rather than silently recording a "passed"/attempt-3 weight
  # check whose result never actually took effect on the registration.
  def apply_registration_result
    if passed?
      unless registration.review!(actor: checked_by, status: :weight_verified)
        errors.add(:base, "could not verify weight check: #{registration.errors[:base].to_sentence}")
        throw :abort
      end
    elsif attempt_number == 3 && !registration.tournament.allow_category_change_at_weigh_in?
      unless registration.review!(actor: checked_by, status: :disqualified)
        errors.add(:base, "could not disqualify athlete: #{registration.errors[:base].to_sentence}")
        throw :abort
      end
    end
  end
end
