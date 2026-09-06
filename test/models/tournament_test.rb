require "test_helper"

class TournamentTest < ActiveSupport::TestCase
  test "fee_label strips trailing zeros for whole-number fees and keeps decimals otherwise" do
    tournament = Tournament.new(registration_fee: 1000, currency: "INR")
    assert_equal "INR 1000", tournament.fee_label

    tournament.registration_fee = 749.5
    assert_equal "INR 749.50", tournament.fee_label

    tournament.registration_fee = nil
    assert_nil tournament.fee_label
  end

  test "end date cannot be before start date" do
    tournament = Tournament.new(name: "Test", start_date: Date.new(2026, 10, 2), end_date: Date.new(2026, 10, 1))
    assert_not tournament.valid?
    assert_includes tournament.errors[:end_date], "cannot be before start date"
  end

  test "registration close must be after open" do
    tournament = Tournament.new(
      name: "Pune Invitational",
      start_date: Date.new(2026, 10, 18),
      end_date: Date.new(2026, 10, 19),
      registration_opens_at: Time.zone.local(2026, 9, 10, 10, 0),
      registration_closes_at: Time.zone.local(2026, 9, 10, 9, 0)
    )

    assert_not tournament.valid?
    assert_includes tournament.errors[:registration_closes_at], "must be after registration opens at"
  end

  test "registration close cannot be after event start date" do
    tournament = Tournament.new(
      name: "Pune Invitational",
      start_date: Date.new(2026, 10, 18),
      end_date: Date.new(2026, 10, 19),
      registration_opens_at: Time.zone.local(2026, 9, 10, 10, 0),
      registration_closes_at: Time.zone.local(2026, 10, 19, 10, 0)
    )

    assert_not tournament.valid?
    assert_includes tournament.errors[:registration_closes_at], "cannot be after the event start date"
  end

  test "accepting registrations requires open status and active window" do
    tournament = Tournament.new(
      name: "Pune Invitational",
      status: :registration_open,
      start_date: Date.new(2026, 10, 18),
      end_date: Date.new(2026, 10, 19),
      registration_opens_at: Time.zone.local(2026, 9, 1, 10, 0),
      registration_closes_at: Time.zone.local(2026, 9, 30, 18, 0)
    )

    assert tournament.accepting_registrations?(at: Time.zone.local(2026, 9, 10, 12, 0))
    assert_not tournament.accepting_registrations?(at: Time.zone.local(2026, 10, 1, 12, 0))

    tournament.status = :registration_paused
    assert_not tournament.accepting_registrations?(at: Time.zone.local(2026, 9, 10, 12, 0))
  end

  test "reads and re-encrypts a payment field that was stored as plaintext before encryption was enabled" do
    organizer = User.create!(name: "Organizer", email: "plaintext-payment-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(
      name: "Plaintext Payment Open", organizer: organizer, registration_fee: 500,
      payment_account_name: "Placeholder", payment_bank_name: "Placeholder", payment_account_number: "0000000000", payment_ifsc: "PLCH0000000",
      start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19)
    )
    ActiveRecord::Base.connection.execute(
      "UPDATE tournaments SET payment_account_name = 'Legacy Plaintext Name' WHERE id = #{tournament.id}"
    )

    reloaded = Tournament.find(tournament.id)
    assert_equal "Legacy Plaintext Name", reloaded.payment_account_name

    reloaded.update!(updated_by: organizer, venue: "New Venue")
    assert_equal "Legacy Plaintext Name", reloaded.reload.payment_account_name
  end

  test "logs an audit entry when payment details are set or changed" do
    organizer = User.create!(name: "Organizer", email: "payment-audit-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(
      name: "Payment Audit Open",
      organizer: organizer,
      updated_by: organizer,
      start_date: Date.new(2026, 10, 18),
      end_date: Date.new(2026, 10, 19),
      payment_account_name: "Pune Taekwondo Association",
      payment_bank_name: "Demo Bank",
      payment_account_number: "1234567890",
      payment_ifsc: "DEMO0001234"
    )

    log = tournament.payment_detail_audit_logs.sole
    assert_equal organizer, log.actor
    assert_equal "payment_account_name, payment_bank_name, payment_account_number, payment_ifsc", log.changed_fields

    tournament.update!(updated_by: organizer, payment_account_number: "9876543210")

    assert_equal 2, tournament.payment_detail_audit_logs.count
    assert_equal "payment_account_number", tournament.payment_detail_audit_logs.order(:created_at).last.changed_fields
  end

  test "does not log a payment detail audit entry when unrelated fields change" do
    organizer = User.create!(name: "Organizer", email: "no-payment-audit-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "No Payment Audit Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))

    tournament.update!(venue: "City Sports Complex")

    assert_equal 0, tournament.payment_detail_audit_logs.count
  end

  test "masks payment account number and IFSC, keeping only the last four characters visible" do
    tournament = Tournament.new(payment_account_number: "1234567890", payment_ifsc: "DEMO0001234")

    assert_equal "••••••7890", tournament.masked_payment_account_number
    assert_equal "•••••••1234", tournament.masked_payment_ifsc
  end

  test "publishing a paid tournament requires payment details" do
    organizer = User.create!(name: "Organizer", email: "missing-payment-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.new(
      name: "Missing Payment Open",
      organizer: organizer,
      status: :registration_open,
      registration_fee: 500,
      start_date: Date.new(2026, 10, 18),
      end_date: Date.new(2026, 10, 19)
    )

    assert_not tournament.valid?
    assert_includes tournament.errors[:base].join, "payment details"
    assert_includes tournament.errors[:payment_account_name], "is required for a tournament that charges a fee"
    assert_includes tournament.errors[:payment_bank_name], "is required for a tournament that charges a fee"
    assert_includes tournament.errors[:payment_account_number], "is required for a tournament that charges a fee"
    assert_includes tournament.errors[:payment_ifsc], "is required for a tournament that charges a fee"

    tournament.payment_account_name = "Pune Taekwondo Association"
    tournament.payment_bank_name = "Demo Bank"
    tournament.payment_account_number = "1234567890"
    tournament.payment_ifsc = "DEMO0001234"

    assert tournament.valid?
  end

  test "a draft tournament can carry a fee without payment details" do
    organizer = User.create!(name: "Organizer", email: "draft-payment-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.new(
      name: "Draft Payment Open",
      organizer: organizer,
      status: :draft,
      registration_fee: 500,
      start_date: Date.new(2026, 10, 18),
      end_date: Date.new(2026, 10, 19)
    )

    assert tournament.valid?
  end

  test "a free published tournament does not require payment details" do
    organizer = User.create!(name: "Organizer", email: "free-payment-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.new(
      name: "Free Payment Open",
      organizer: organizer,
      status: :registration_open,
      registration_fee: 0,
      start_date: Date.new(2026, 10, 18),
      end_date: Date.new(2026, 10, 19)
    )

    assert tournament.valid?
  end

  test "every tournament is seeded with all default categories on creation" do
    organizer = User.create!(name: "Organizer", email: "default-categories-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Default Categories Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))

    assert_equal TournamentCategory::DEFAULT_CATEGORY_TEMPLATES.size, tournament.tournament_categories.count
    assert_equal "Default categories", tournament.category_generation_method
  end

  test "cannot move a cancelled tournament back to an active status" do
    organizer = User.create!(name: "Organizer", email: "cancelled-status-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Cancelled Open", organizer: organizer, status: :registration_open, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    tournament.update!(status: :cancelled)

    tournament.status = :registration_open
    assert_not tournament.valid?
    assert_includes tournament.errors[:status], "cannot change from cancelled to registration open"

    tournament.status = :archived
    assert tournament.valid?
  end

  test "cannot move a completed tournament back to an active status" do
    organizer = User.create!(name: "Organizer", email: "completed-status-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Completed Open", organizer: organizer, status: :registration_open, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    tournament.update!(status: :completed)

    tournament.status = :in_progress
    assert_not tournament.valid?
    assert_includes tournament.errors[:status], "cannot change from completed to in progress"
  end

  test "archived tournament cannot change status at all" do
    organizer = User.create!(name: "Organizer", email: "archived-status-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Archived Open", organizer: organizer, status: :cancelled, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    tournament.update!(status: :archived)

    tournament.status = :draft
    assert_not tournament.valid?
  end

  test "active statuses can move freely between each other" do
    organizer = User.create!(name: "Organizer", email: "active-status-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Active Open", organizer: organizer, status: :draft, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))

    tournament.status = :registration_open
    assert tournament.valid?
    tournament.save!

    tournament.status = :registration_paused
    assert tournament.valid?
  end

  test "rejects a primary contact phone that is not exactly 10 digits" do
    tournament = Tournament.new(name: "Pune Invitational", start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19), primary_contact_phone: "98765abcde")

    assert_not tournament.valid?
    assert_includes tournament.errors[:primary_contact_phone], "must be a 10-digit mobile number"

    tournament.primary_contact_phone = "9876543210"
    tournament.valid?
    assert_empty tournament.errors[:primary_contact_phone]
  end

  test "rejects unsupported tournament logo upload type" do
    organizer = User.create!(name: "Organizer", email: "logo-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.new(name: "Logo Upload Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    tournament.logo_image.attach(invalid_text_upload)

    assert_not tournament.valid?
    assert_includes tournament.errors[:logo_image], "must be a JPG, PNG, or WebP file"
  end

  test "rejects unsupported tournament banner upload type" do
    organizer = User.create!(name: "Organizer", email: "banner-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.new(name: "Banner Upload Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    tournament.banner_image.attach(invalid_text_upload)

    assert_not tournament.valid?
    assert_includes tournament.errors[:banner_image], "must be a JPG, PNG, or WebP file"
  end

  test "rejects a tournament logo whose content does not match its declared image type" do
    organizer = User.create!(name: "Organizer", email: "spoofed-logo-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.new(name: "Spoofed Logo Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    spoofed_upload = Rack::Test::UploadedFile.new(StringIO.new("MZ\x90\x00\x03\x00\x00\x00\x04\x00\x00\x00\xFF\xFF\x00\x00"), "image/png", original_filename: "logo.png")
    tournament.logo_image.attach(spoofed_upload)

    assert_not tournament.valid?
    assert_includes tournament.errors[:logo_image], "must be a JPG, PNG, or WebP file"
  end

  test "rejects tournament branding uploads over five megabytes" do
    organizer = User.create!(name: "Organizer", email: "large-branding-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.new(name: "Large Branding Open", organizer: organizer, start_date: Date.new(2026, 10, 18), end_date: Date.new(2026, 10, 19))
    tournament.logo_image.attach(oversized_upload)
    tournament.banner_image.attach(oversized_upload(filename: "oversized-banner.png"))

    assert_not tournament.valid?
    assert_includes tournament.errors[:logo_image], "must be 5 MB or smaller"
    assert_includes tournament.errors[:banner_image], "must be 5 MB or smaller"
  end
end
