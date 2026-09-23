class Tournament < ApplicationRecord
  include ConsentRecordable
  include AttachmentContentTypeValidatable
  include EmailFormatValidatable

  MAX_IMAGE_SIZE = 5.megabytes
  ACCEPTED_IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze
  PAYMENT_DETAIL_FIELDS = %w[payment_account_name payment_bank_name payment_account_number payment_ifsc].freeze
  PAYMENT_AUDIT_FIELDS = PAYMENT_DETAIL_FIELDS + %w[payment_upi_id]
  UPI_ID_FORMAT = /\A[\w.+-]{2,256}@[a-zA-Z]{2,64}\z/

  INDIAN_STATES_AND_UNION_TERRITORIES = IndianLocation::STATES

  attr_accessor :updated_by

  encrypts :payment_account_name, :payment_bank_name, :payment_account_number, :payment_ifsc, :payment_upi_id

  before_validation :normalize_fields
  before_validation :sync_status_with_registration_window

  belongs_to :organizer, class_name: "User"
  has_many :tournament_categories, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :tournament_organizers, dependent: :destroy
  has_many :organizer_users, through: :tournament_organizers, source: :user
  has_many :tournament_organizer_invitations, dependent: :destroy
  has_many :tournament_referees, dependent: :destroy
  has_many :payment_detail_audit_logs, dependent: :destroy
  has_one_attached :logo_image
  has_one_attached :banner_image

  DEFAULT_COMPETITION_FORMATS = [
    "Kyorugi",
    "Individual Poomsae",
    "Team Poomsae"
  ].freeze

  DEFAULT_ELIGIBILITY_RULES = [
    "Age proof required",
    "Valid academy or association membership",
    "Medical fitness declaration",
    "Minimum belt requirement",
    "Guardian consent for minors"
  ].freeze

  DEFAULT_REQUIRED_DOCUMENTS = [
    "Age proof",
    "Government identity proof",
    "Academy approval letter",
    "Association ID",
    "Medical clearance"
  ].freeze

  DEFAULT_REFUND_POLICIES = [
    "Full refund before registration closes",
    "Partial refund after registration closes",
    "No refund after final schedules are published",
    "Refund only if event is cancelled",
    "Transfer registration to another athlete is not allowed"
  ].freeze

  enum :status, {
    draft: 0,
    registration_open: 1,
    registration_closed: 2,
    in_progress: 3,
    completed: 4,
    cancelled: 5,
    ready_for_review: 6,
    scheduled: 7,
    registration_paused: 8,
    archived: 10
  }, default: :draft

  # Cancelled/completed/archived are wind-down states: once a tournament
  # reaches one of them it should not be reactivated into an active state by
  # mistake. Every other status can still move freely between each other
  # (organizers manage the day-to-day lifecycle from one status dropdown).
  LOCKED_STATUS_TRANSITIONS = {
    "cancelled" => %w[archived],
    "completed" => %w[archived],
    "archived" => []
  }.freeze

  CLOSED_OUT_STATUSES = %w[cancelled archived].freeze

  # When an organizer deletes their account, only tournaments still "in
  # play" are removed — anything that already concluded (or was called off)
  # is kept exactly as-is, since it's now part of the historical record.
  PRESERVED_ON_ACCOUNT_DELETION_STATUSES = %w[completed cancelled archived].freeze

  validates :name, :start_date, :end_date, presence: true
  validates :name, length: { minimum: 3, maximum: 120 }, allow_blank: true
  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid http or https URL" }, allow_blank: true
  validates :primary_contact_email, format: { with: EmailFormatValidatable::STRICT_EMAIL_REGEXP }, allow_blank: true
  rejects_placeholder_email :primary_contact_email
  validates :primary_contact_phone, format: { with: User::PHONE_FORMAT, message: "must be a 10-digit mobile number" }, allow_blank: true
  validates :registration_capacity, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
  validates :registration_fee, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :group_registration_fee, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :courts_count, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
  validates :payment_upi_id, format: { with: UPI_ID_FORMAT, message: "must be a valid UPI ID (e.g. name@bank)" }, allow_blank: true
  validates :pincode, format: { with: IndianLocation::PINCODE_FORMAT, message: "must be a valid 6-digit PIN code" }, allow_blank: true
  validate :end_date_not_before_start_date
  validate :registration_window_chronology
  validate :logo_image_size
  validate :banner_image_size
  validate :payment_details_present_when_charging_fee
  validate :status_transition_allowed

  after_create :add_creator_as_super_organizer
  after_create :assign_default_categories
  after_save :log_payment_detail_changes

  def accepting_registrations?(at: Time.current)
    registration_open? && registration_window_open?(at: at)
  end

  def registration_window_open?(at: Time.current)
    (registration_opens_at.blank? || registration_opens_at <= at) &&
      (registration_closes_at.blank? || registration_closes_at >= at)
  end

  def registration_closed_for_weight_check?(at: Time.current)
    registration_closes_at.present? && registration_closes_at < at
  end

  # Used to gate draw generation: true only when an explicit close date has
  # been set and hasn't passed yet. A tournament with no close date at all
  # isn't treated as "still open" here — there's nothing to wait for — so
  # this is deliberately not just the inverse of
  # registration_closed_for_weight_check?.
  def registration_still_open_for_draw?(at: Time.current)
    registration_closes_at.present? && registration_closes_at >= at
  end

  # A generated draw is the point of no return for the event's physical
  # setup — once athletes are placed in the bracket, the number of courts
  # etc. shouldn't move under them. Editable at any time before that,
  # including before registration even opens.
  def venue_setup_locked?
    tournament_categories.where.not(draw_generated_at: nil).exists?
  end

  def late_registration_allowed_for?(user)
    return false unless user
    user.super_admin? || tournament_organizers.super_organizer.exists?(user_id: user.id)
  end

  def managed_by?(user)
    return false unless user

    organizer_id == user.id || tournament_organizers.exists?(user_id: user.id)
  end

  # Collaborators can help run the event (approve registrations, weigh-ins,
  # draws) but not touch financially/organizationally sensitive settings —
  # only the owner or a super_organizer collaborator can.
  def managed_by_super_organizer?(user)
    return false unless user

    organizer_id == user.id || tournament_organizers.super_organizer.exists?(user_id: user.id)
  end

  # The individual fee is expected on every tournament, so leaving it blank
  # is treated as "not decided yet" (not free). The group fee only applies
  # to tournaments that offer pair/team Poomsae at all, so a tournament that
  # never sets it is simply not charging for group entries, not "undecided".
  def free?
    fee_present_and_zero?(registration_fee) && (group_registration_fee.blank? || group_registration_fee.to_d.zero?)
  end

  def fee_label
    individual = formatted_fee(registration_fee)
    group = formatted_fee(group_registration_fee)
    return "#{individual} individual · #{group} group" if individual && group
    return individual if individual

    group
  end

  def closed_out?
    status.in?(CLOSED_OUT_STATUSES)
  end

  def masked_payment_account_number
    mask_trailing(payment_account_number)
  end

  def masked_payment_ifsc
    mask_trailing(payment_ifsc)
  end

  def masked_payment_upi_id
    mask_trailing(payment_upi_id)
  end

  # Renders a scannable UPI QR code directly from the organizer's UPI ID —
  # generated fresh on every call (cheap, pure-Ruby, no network call and
  # nothing written to disk), so there's no separate image to upload, store,
  # or keep in sync with the UPI ID. Returns nil when there's no valid UPI ID
  # to encode. The SVG markup is entirely generated by the rqrcode gem from
  # the QR module matrix, not by interpolating any of our strings into
  # markup, so it's safe to mark html_safe.
  def payment_upi_qr_svg
    return unless payment_upi_id.present? && payment_upi_id.match?(UPI_ID_FORMAT)

    RQRCode::QRCode.new(payment_upi_uri, level: :m)
      .as_svg(offset: 0, color: "000", shape_rendering: "crispEdges", module_size: 6, standalone: true, viewbox: true)
      .html_safe
  end

  def logo_image_source
    logo_image if logo_image.attached?
  end

  def banner_image_source
    banner_image if banner_image.attached?
  end

  def assign_default_categories
    update_column(:category_generation_method, "Default categories") if category_generation_method != "Default categories"

    TournamentCategory::DEFAULT_CATEGORY_TEMPLATES.each do |template|
      tournament_categories.find_or_create_by!(template.except(:key))
    end
  end

  private

  def fee_present_and_zero?(fee)
    fee.present? && fee.to_d.zero?
  end

  def formatted_fee(fee)
    return unless fee.present?

    decimal = fee.to_d
    formatted = decimal.frac.zero? ? decimal.to_i.to_s : format("%.2f", decimal)
    "#{currency.presence || "INR"} #{formatted}"
  end

  def normalize_fields
    self.name = name.to_s.squish.presence
    self.website_url = website_url.to_s.squish.presence
    self.city = city.to_s.squish.presence
    self.state = state.to_s.squish.presence
    self.country = country.to_s.squish.presence || "India"
    self.tournament_level = tournament_level.to_s.squish.presence
    self.organizing_organization = organizing_organization.to_s.squish.presence
    self.time_zone = time_zone.to_s.squish.presence
    self.primary_contact_name = primary_contact_name.to_s.squish.presence
    self.primary_contact_email = primary_contact_email.to_s.downcase.squish.presence
    self.primary_contact_phone = primary_contact_phone.to_s.squish.presence
    self.competition_formats = competition_formats.to_s.squish.presence
    self.eligibility_summary = eligibility_summary.to_s.squish.presence
    self.category_generation_method = category_generation_method.to_s.squish.presence
    self.currency = currency.to_s.upcase.squish.presence
    self.required_documents = required_documents.to_s.squish.presence
    self.refund_policy = refund_policy.to_s.squish.presence
    self.payment_account_name = payment_account_name.to_s.squish.presence
    self.payment_bank_name = payment_bank_name.to_s.squish.presence
    self.payment_account_number = payment_account_number.to_s.squish.presence
    self.payment_ifsc = payment_ifsc.to_s.upcase.squish.presence
    self.payment_upi_id = payment_upi_id.to_s.downcase.squish.presence
    self.payment_instructions = payment_instructions.to_s.squish.presence
  end

  # If an organizer or super admin edits the registration window on an
  # existing tournament, keep the status in sync with the new dates instead
  # of leaving it stale (e.g. re-extending a closed registration window
  # should reopen registration, and pulling the close date into the past
  # should close it) — this only moves the status between the two
  # calendar-driven states themselves; a deliberate "registration_paused"
  # override, or any other status, is left alone.
  def sync_status_with_registration_window
    return if new_record?
    return unless will_save_change_to_registration_opens_at? || will_save_change_to_registration_closes_at?
    return unless status.in?(%w[registration_open registration_closed])

    self.status = registration_window_open? ? "registration_open" : "registration_closed"
  end

  # A registrant needs exactly one working way to pay, not both — full bank
  # transfer details and a UPI ID (which also gets you an auto-generated QR
  # code, see #payment_upi_qr_svg) are independent, equally valid payment
  # methods, so either complete method is enough to publish a paid
  # tournament.
  def payment_details_present_when_charging_fee
    return if draft?
    return unless registration_fee.to_d.positive? || group_registration_fee.to_d.positive?
    return if any_payment_method_present?

    errors.add(:base, "add at least one payment method (bank account details or a UPI ID) before a tournament that charges a fee can be published")

    # Only pile on per-field errors if the organizer clearly started filling
    # in bank transfer details — otherwise a UPI-only organizer would see
    # four confusing "required" errors for fields they never intended to use.
    return unless PAYMENT_DETAIL_FIELDS.any? { |field| send(field).present? }

    PAYMENT_DETAIL_FIELDS.select { |field| send(field).blank? }.each do |field|
      errors.add(field.to_sym, "is required for a tournament that charges a fee")
    end
  end

  def any_payment_method_present?
    PAYMENT_DETAIL_FIELDS.all? { |field| send(field).present? } || payment_upi_id.present?
  end

  def status_transition_allowed
    return if new_record? || !status_changed?

    allowed = LOCKED_STATUS_TRANSITIONS[status_was]
    return if allowed.nil? || allowed.include?(status)

    errors.add(:status, "cannot change from #{status_was.humanize.downcase} to #{status.humanize.downcase}")
  end

  def end_date_not_before_start_date
    return if start_date.blank? || end_date.blank?
    errors.add(:end_date, "cannot be before start date") if end_date < start_date
  end

  def registration_window_chronology
    if registration_opens_at.present? && registration_closes_at.present? && registration_opens_at >= registration_closes_at
      errors.add(:registration_closes_at, "must be after registration opens at")
    end

    if registration_closes_at.present? && start_date.present? && registration_closes_at.to_date > start_date
      errors.add(:registration_closes_at, "cannot be after the event start date")
    end
  end

  def add_creator_as_super_organizer
    tournament_organizers.find_or_create_by!(user: organizer) do |membership|
      membership.role = :super_organizer
      membership.added_by = organizer
    end
  end

  def log_payment_detail_changes
    changed_fields = PAYMENT_AUDIT_FIELDS & saved_changes.keys
    return if changed_fields.empty?

    payment_detail_audit_logs.create!(actor: updated_by, changed_fields: changed_fields.join(", "))
  end

  def mask_trailing(value, visible: 4)
    return if value.blank?
    return value if value.length <= visible

    ("•" * (value.length - visible)) + value.last(visible)
  end

  # Builds the `upi://pay` deep link the QR code encodes. Every value is
  # percent-encoded through URI.encode_www_form_component before being
  # dropped into the query string — payment_upi_id is already restricted to
  # a safe character set by UPI_ID_FORMAT, but payment_account_name/name are
  # free text an organizer controls, so without encoding a value containing
  # "&" or "=" could inject extra params (e.g. a bogus amount) into the deep
  # link a payer's UPI app opens.
  def payment_upi_uri
    payee_name = payment_account_name.presence || name
    params = { pa: payment_upi_id, pn: payee_name, cu: "INR", tn: "Payment for #{name}" }
    query = params.map { |key, value| "#{key}=#{URI.encode_www_form_component(value.to_s)}" }.join("&")
    "upi://pay?#{query}"
  end

  def logo_image_size
    validate_image_upload(logo_image, :logo_image)
  end

  def banner_image_size
    validate_image_upload(banner_image, :banner_image)
  end

  def validate_image_upload(attachment, attribute)
    return unless attachment.attached?

    errors.add(attribute, "must be 5 MB or smaller") if attachment.blob.byte_size > MAX_IMAGE_SIZE
    errors.add(attribute, "must be a JPG, PNG, or WebP file") unless attachment_content_type_allowed?(attachment, ACCEPTED_IMAGE_TYPES)
  end
end
