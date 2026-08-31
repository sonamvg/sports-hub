require "test_helper"

class AcademyTest < ActiveSupport::TestCase
  test "approved academies are visible to public" do
    academy = Academy.new(name: "Deccan Taekwondo Academy", city: "Pune", status: :approved)

    assert academy.visible_to_public?
  end

  test "pending academies are not visible to public" do
    academy = Academy.new(name: "Deccan Taekwondo Academy", city: "Pune", status: :pending)

    assert_not academy.visible_to_public?
  end

  test "academy logo must be jpg or png" do
    academy = Academy.new(name: "Deccan Taekwondo Academy", city: "Pune")
    academy.logo_image.attach(io: StringIO.new("%PDF-1.4"), filename: "logo.pdf", content_type: "application/pdf")

    assert_not academy.valid?
    assert_includes academy.errors[:logo_image], "file size should be less than 5 MB and PNG/JPG is accepted"
  end
end
