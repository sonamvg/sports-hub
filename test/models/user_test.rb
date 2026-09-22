require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "rejects a name containing digits or symbols" do
    user = User.new(name: "Sritha3!", email: "bad-name@example.test", password: "password123")

    assert_not user.valid?
    assert_includes user.errors[:name], "can only contain letters, spaces, hyphens, and apostrophes"
  end

  test "accepts a hyphenated or multi-word name" do
    user = User.new(name: "Anne-Marie O'Brien", email: "good-name@example.test", password: "password123")

    user.valid?
    assert_empty user.errors[:name]
  end

  test "rejects a phone number that is not exactly 10 digits" do
    user = User.new(name: "Sritha", email: "bad-phone@example.test", password: "password123", phone: "12345")

    assert_not user.valid?
    assert_includes user.errors[:phone], "must be a 10-digit mobile number"
  end

  test "rejects a phone number containing letters" do
    user = User.new(name: "Sritha", email: "bad-phone-letters@example.test", password: "password123", phone: "98765abcde")

    assert_not user.valid?
    assert_includes user.errors[:phone], "must be a 10-digit mobile number"
  end

  test "rejects an email with an invalid format" do
    user = User.new(name: "Sritha", email: "not-an-email", password: "password123")

    assert_not user.valid?
    assert_includes user.errors[:email], "must be a valid email address"
  end

  test "rejects an email domain with no dot or TLD" do
    user = User.new(name: "Sritha", email: "sonam@test", password: "password123")

    assert_not user.valid?
    assert_includes user.errors[:email], "must be a valid email address"
  end

  test "rejects a placeholder or example email domain" do
    user = User.new(name: "Sritha", email: "sritha@example.com", password: "password123")

    assert_not user.valid?
    assert_includes user.errors[:email], "must be a real email address, not a placeholder or test domain"

    user.email = "test@test.com"
    assert_not user.valid?
    assert_includes user.errors[:email], "must be a real email address, not a placeholder or test domain"
  end

  test "rejects manually setting an email on the reserved placeholder domain" do
    user = User.new(name: "Sritha", email: "someone@#{User::PLACEHOLDER_EMAIL_DOMAIN}", password: "password123")

    assert_not user.valid?
    assert_includes user.errors[:email], "cannot use a reserved address"
  end

  test "allows a generated placeholder email when placeholder_email is set" do
    user = User.new(name: "Sritha", email: User.generate_placeholder_email, placeholder_email: true, password: "password123")

    user.valid?
    assert_empty user.errors[:email]
  end

  test "does not enqueue a password reset email for placeholder accounts" do
    user = User.create!(name: "Sritha", email: User.generate_placeholder_email, placeholder_email: true, password: "password123")

    assert_no_enqueued_emails do
      user.send_password_reset_email
    end
  end

  test "deactivate! clears sign-in details but keeps the name and stays queryable" do
    user = User.create!(name: "Deactivate Me", email: "deactivate-target@example.test", phone: "9876543210", password: "password123", role: :organizer)

    user.deactivate!

    assert_predicate user, :deactivated?
    assert_not_nil user.deactivated_at
    assert_equal "deleted-user-#{user.id}@#{User::DEACTIVATED_EMAIL_DOMAIN}", user.email
    assert_nil user.phone
    assert_equal "Deactivate Me", user.name
    assert_not user.authenticate("password123")
  end

  test "verified_organizers and pending_organizers exclude deactivated accounts" do
    verified = User.create!(name: "Verified Organizer", email: "active-verified-organizer@example.test", password: "password123", role: :organizer, organizer_status: :verified)
    pending = User.create!(
      name: "Pending Organizer", email: "active-pending-organizer@example.test", password: "password123",
      role: :organizer, organizer_status: :pending, phone: "9876543210", organizer_designation: "Event Director",
      identity_document: identity_document_upload
    )

    assert_includes User.verified_organizers, verified
    assert_includes User.pending_organizers, pending

    verified.deactivate!
    pending.deactivate!

    assert_not_includes User.verified_organizers, verified
    assert_not_includes User.pending_organizers, pending
  end

  test "rejects a password shorter than 8 characters" do
    user = User.new(name: "Sritha", email: "short-password@example.test", password: "abc123")

    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "rejects a password containing spaces" do
    user = User.new(name: "Sritha", email: "spaced-password@example.test", password: "pass word1")

    assert_not user.valid?
    assert_includes user.errors[:password], "must include at least one letter and one number, with no spaces"
  end

  test "rejects a password without a number" do
    user = User.new(name: "Sritha", email: "letters-only-password@example.test", password: "passwordonly")

    assert_not user.valid?
    assert_includes user.errors[:password], "must include at least one letter and one number, with no spaces"
  end

  test "accepts a password with letters, numbers, and no spaces" do
    user = User.new(name: "Sritha", email: "good-password@example.test", password: "password123")

    user.valid?
    assert_empty user.errors[:password]
  end

  test "academy owner cannot organize tournaments" do
    user = User.new(name: "Academy Owner", email: "no-organize@example.test", password: "password123", role: :academy_owner)

    assert_not user.can_organize_tournaments?
  end

  test "verified organizer can organize tournaments" do
    user = User.new(name: "Verified Organizer", email: "verified-organize@example.test", password: "password123", role: :organizer, organizer_status: :verified)

    assert user.can_organize_tournaments?
  end

  test "rejects unsupported organizer identity document upload type" do
    user = User.new(
      name: "Pending Organizer",
      email: "pending-organizer-upload@example.test",
      phone: "9876543210",
      organizer_designation: "Tournament Director",
      password: "password123",
      password_confirmation: "password123",
      role: :organizer,
      organizer_status: :pending
    )
    user.identity_document.attach(invalid_text_upload)

    assert_not user.valid?
    assert_includes user.errors[:identity_document], "must be a JPG, PNG, or PDF file"
  end

  test "rejects organizer identity document uploads over five megabytes" do
    user = User.new(
      name: "Pending Organizer",
      email: "pending-organizer-large-upload@example.test",
      phone: "9876543210",
      organizer_designation: "Tournament Director",
      password: "password123",
      password_confirmation: "password123",
      role: :organizer,
      organizer_status: :pending
    )
    user.identity_document.attach(oversized_upload(filename: "identity.pdf", content_type: "application/pdf"))

    assert_not user.valid?
    assert_includes user.errors[:identity_document], "must be 5 MB or smaller"
  end
end
