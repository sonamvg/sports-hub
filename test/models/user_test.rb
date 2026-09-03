require "test_helper"

class UserTest < ActiveSupport::TestCase
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
