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

  test "rejects a placeholder or example email domain" do
    user = User.new(name: "Sritha", email: "sritha@example.com", password: "password123")

    assert_not user.valid?
    assert_includes user.errors[:email], "must be a real email address, not a placeholder or test domain"

    user.email = "test@test.com"
    assert_not user.valid?
    assert_includes user.errors[:email], "must be a real email address, not a placeholder or test domain"
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
