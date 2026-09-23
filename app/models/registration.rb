class Registration < ApplicationRecord
  include AttachmentContentTypeValidatable

  MAX_PAYMENT_RECEIPT_SIZE = 5.megabytes
  ACCEPTED_PAYMENT_RECEIPT_TYPES = %w[image/jpeg image/png image/webp application/pdf].freeze

  belongs_to :tournament
  belongs_to :athlete
  belongs_to :tournament_category
  belongs_to :moved_from_registration, class_name: "Registration", optional: true
  has_many :registration_action_logs, dependent: :destroy
  has_many :registration_weight_checks, dependent: :destroy
  has_one_attached :payment_receipt

  enum :status, { pending: 0, approved: 1, rejected: 2, withdrawn: 3, weight_verified: 4, disqualified: 5, draft: 6 }, default: :pending

  # A `draft` registration is an in-progress cart row the submitter hasn't
  # finished/paid for yet — it isn't a real registration attempt to anyone
  # else. Every list/count of "actual" registrations (organizer queues,
  # public tournament pages, an athlete's own history, an academy's roster)
  # must use this scope rather than querying Registration directly, so a new
  # caller can't forget to exclude it.
  scope :decided, -> { where.not(status: :draft) }

  VALID_REVIEW_TRANSITIONS = {
    "approved" => "pending",
    "rejected" => "pending",
    "weight_verified" => "approved",
    "disqualified" => "approved",
    "withdrawn" => "approved"
  }.freeze

  validates :athlete_id, uniqueness: { scope: [:tournament_id, :tournament_category_id] }
  validates :registered_weight, numericality: { greater_than: 0, less_than_or_equal_to: 999.99 }, allow_nil: true
  validates :payment_note, length: { maximum: 500 }, allow_blank: true
  validate :payment_receipt_required
  validate :payment_receipt_size
  validate :category_belongs_to_tournament
  validate :athlete_matches_category_eligibility
  before_validation :assign_fee_snapshot

  def review!(actor:, status:)
    with_lock do
      if VALID_REVIEW_TRANSITIONS[status.to_s] != self.status
        errors.add(:base, "already reviewed")
        return false
      end

      if tournament.closed_out?
        errors.add(:base, "tournament has been #{tournament.status}")
        return false
      end

      from_status = self.status
      # A pure status transition shouldn't be blocked by unrelated attributes
      # (e.g. a payment receipt that fails today's stricter content-type
      # check but was accepted under yesterday's rules) re-failing full-record
      # validation on every save. Skip validations here; the transition
      # itself is already guarded above.
      assign_attributes(status: status, verified_at: Time.current)
      save!(validate: false)
      registration_action_logs.create!(
        actor: actor,
        action: status.to_s,
        from_status: from_status,
        to_status: self.status
      )
    end

    true
  end

  def next_weight_check_attempt_number
    registration_weight_checks.maximum(:attempt_number).to_i + 1
  end

  def weight_check_attempts_remaining?
    approved? && registration_weight_checks.size < 3 && !tournament_category.draw_generated?
  end

  def weight_within_category?(weight)
    measured_weight = weight.to_d
    min = tournament_category.weight_min
    max = tournament_category.weight_max

    (min.blank? || measured_weight >= min) && (max.blank? || measured_weight <= max)
  end

  def category_weight_range
    min = tournament_category.weight_min
    max = tournament_category.weight_max

    if min.present? && max.present?
      "#{formatted_weight(min)}-#{formatted_weight(max)} kg"
    elsif min.present?
      "Over #{formatted_weight(min)} kg"
    elsif max.present?
      "Up to #{formatted_weight(max)} kg"
    else
      "Open"
    end
  end

  def fee_label
    "#{fee_currency.presence || tournament.currency.presence || "INR"} #{formatted_currency(fee_amount || 0)}"
  end

  # The fee for a batch of registrations (a Pair/Team Poomsae entry, or one
  # or more individual categories submitted together) sums every row: the
  # group/Poomsae fee an organizer sets on a tournament is a per-athlete
  # rate, not a flat per-team price, so a Pair entry (2 rows) is meant to
  # come to double that rate and a Team entry (3 rows) triple it — matching
  # each row's own fee_amount, which is already that same per-athlete rate.
  def self.total_fee(registrations)
    registrations
      .reject { |registration| registration.tournament_category.free? }
      .sum { |registration| registration.fee_amount.to_d }
  end

  def athlete_status_label
    case status
    when "pending" then "Submitted"
    when "approved" then "Registered"
    when "rejected" then "Declined"
    when "weight_verified" then "Weight verified"
    when "disqualified" then "Disqualified"
    when "withdrawn" then "Withdrawn"
    when "draft" then "Draft"
    else status.to_s.humanize
    end
  end

  def athlete_status_detail
    if rejected?
      "Your registration was not approved by the tournament organiser."
    elsif weight_verified?
      "Weight check is complete."
    elsif disqualified?
      "Weight check is complete. This entry was disqualified."
    elsif approved?
      "Your registration has been accepted by the organiser."
    elsif withdrawn?
      "This registration was withdrawn."
    end
  end

  def weight_check_summary
    registration_weight_checks.order(:attempt_number).map do |check|
      result = check.passed? ? "passed" : "failed"
      "Attempt #{check.attempt_number}: #{formatted_weight(check.weight)} kg #{result}"
    end
  end

  def weight_check_decision_pending?
    approved? && registration_weight_checks.size == 3 && !registration_weight_checks.order(:attempt_number).last.passed?
  end

  def eligible_category_change_targets
    tournament.tournament_categories
      .where(event_type: tournament_category.event_type, gender: tournament_category.gender,
             age_min: tournament_category.age_min, age_max: tournament_category.age_max)
      .where.not(id: tournament_category_id)
      .order(:weight_min)
  end

  def recommended_category_change_target
    last_weight = registration_weight_checks.order(:attempt_number).last&.weight
    return eligible_category_change_targets.first if last_weight.blank?

    eligible_category_change_targets.min_by do |category|
      bounds = [category.weight_min, category.weight_max].compact
      midpoint = bounds.sum / bounds.size.to_f
      (last_weight.to_d - midpoint).abs
    end
  end

  def move_to_category!(category:, actor:)
    last_weight = registration_weight_checks.order(:attempt_number).last&.weight

    transaction do
      review!(actor: actor, status: :withdrawn)

      new_registration = tournament.registrations.build(
        athlete: athlete,
        tournament_category: category,
        status: :approved,
        verified_at: Time.current,
        registered_weight: last_weight,
        fee_amount: fee_amount,
        fee_currency: fee_currency,
        moved_from_registration: self
      )
      new_registration.payment_receipt.attach(payment_receipt.blob) if payment_receipt.attached?
      new_registration.save!
      new_registration.registration_action_logs.create!(actor: actor, action: "approved", from_status: nil, to_status: "approved")
      new_registration
    end
  end

  private

  def category_belongs_to_tournament
    return if tournament.blank? || tournament_category.blank?
    errors.add(:tournament_category, "must belong to the selected tournament") if tournament_category.tournament_id != tournament_id
  end

  # Gender, age, and belt are fixed facts that make a category a genuine
  # mismatch, so they still block registration. Weight is deliberately left
  # out here: an athlete's weight on registration day is only an estimate —
  # it commonly shifts by weigh-in — so registering shouldn't lock someone
  # out of a bracket just because today's number doesn't fit. The real
  # weight check happens at the tournament's weigh-in (see
  # RegistrationWeightCheck / #weight_within_category?), which can also move
  # a registration to a better-fitting category if it's off.
  def athlete_matches_category_eligibility
    return if athlete.blank? || tournament_category.blank?

    tournament_category.eligibility_errors_for(athlete, as_of: tournament&.start_date).each do |message|
      errors.add(:base, message)
    end
  end

  def payment_receipt_required
    return if draft? || tournament_category&.free?
    # No bank/UPI details on file means the organizer is collecting payment
    # in cash (or by other off-platform arrangement) — there's nothing to
    # attach a formal receipt against, so it's optional (see #payment_note).
    # Same when this particular registrant chose to pay by cash/UPI directly
    # (e.g. to a coach) on a tournament that otherwise takes bank/UPI too.
    return unless tournament&.any_payment_method_present?
    return if paid_by_cash?

    errors.add(:payment_receipt, "must be uploaded") unless payment_receipt.attached?
  end

  def payment_receipt_size
    return unless payment_receipt.attached?

    errors.add(:payment_receipt, "must be 5 MB or smaller") if payment_receipt.blob.byte_size > MAX_PAYMENT_RECEIPT_SIZE
    errors.add(:payment_receipt, "must be a JPG, PNG, WebP, or PDF file") unless attachment_content_type_allowed?(payment_receipt, ACCEPTED_PAYMENT_RECEIPT_TYPES)
  end

  def formatted_weight(weight)
    decimal = weight.to_d
    decimal.frac.zero? ? decimal.to_i.to_s : decimal.to_s("F").sub(/0+\z/, "").sub(/\.\z/, "")
  end

  def assign_fee_snapshot
    return if tournament.blank?

    self.fee_amount ||= tournament_category&.effective_registration_fee || 0
    self.fee_currency ||= tournament.currency.presence || "INR"
  end

  def formatted_currency(amount)
    decimal = amount.to_d
    decimal.frac.zero? ? decimal.to_i.to_s : format("%.2f", decimal)
  end
end
