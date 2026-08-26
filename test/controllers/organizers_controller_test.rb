require "test_helper"

class OrganizersControllerTest < ActionDispatch::IntegrationTest
  test "signed out users see organizer registration CTA and verified organizers" do
    organizer = User.create!(
      name: "Verified Organizer",
      email: "verified-organizer@example.test",
      password: "password123",
      role: :organizer,
      profile_photo_url: "https://example.com/photo.jpg"
    )
    Tournament.create!(
      name: "City Open",
      organizer: organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
    User.create!(
      name: "Pending Organizer",
      email: "pending-organizer@example.test",
      password: "password123",
      role: :organizer,
      organizer_status: :pending,
      phone: "9876543210",
      organizer_designation: "Event Director",
      identity_document: identity_document_upload
    )

    get organizers_path

    assert_response :success
    assert_includes response.body, "Have an event in mind?"
    assert_includes response.body, "Register as organizer"
    assert_includes response.body, "Verified Organizer"
    assert_includes response.body, "Verified Organizer photo"
    assert_includes response.body, "City Open"
    assert_not_includes response.body, "Pending Organizer"
  end

  test "super admin can verify pending organizer" do
    super_admin = User.create!(name: "Super Admin", email: "admin@example.test", password: "password123", role: :super_admin)
    organizer = User.create!(
      name: "Pending Organizer",
      email: "pending-organizer@example.test",
      password: "password123",
      role: :organizer,
      organizer_status: :pending,
      phone: "9876543210",
      organizer_designation: "Event Director",
      identity_document: identity_document_upload
    )
    sign_in_as super_admin

    patch approve_organizer_path(organizer)

    assert_redirected_to organizers_path
    organizer.reload
    assert_predicate organizer, :organizer_verified?
    assert_equal super_admin, organizer.organizer_reviewed_by
    assert_not_nil organizer.organizer_approved_at
  end

  test "non super admin cannot verify organizer" do
    user = User.create!(name: "Organizer", email: "organizer@example.test", password: "password123", role: :organizer)
    pending = User.create!(
      name: "Pending Organizer",
      email: "pending@example.test",
      password: "password123",
      role: :organizer,
      organizer_status: :pending,
      phone: "9876543210",
      organizer_designation: "Event Director",
      identity_document: identity_document_upload
    )
    sign_in_as user

    patch approve_organizer_path(pending)

    assert_response :not_found
    assert_predicate pending.reload, :organizer_pending?
  end
end
