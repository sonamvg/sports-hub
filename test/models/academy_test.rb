require "test_helper"

class AcademyTest < ActiveSupport::TestCase
  test "rejects a duplicate academy name in the same city, case-insensitively" do
    Academy.create!(name: "Deccan Taekwondo Academy", city: "Pune")
    duplicate = Academy.new(name: "deccan taekwondo academy", city: "Pune")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "already exists in this city"
  end

  test "allows the same academy name in a different city" do
    Academy.create!(name: "Deccan Taekwondo Academy", city: "Pune")
    other_city = Academy.new(name: "Deccan Taekwondo Academy", city: "Mumbai")

    assert other_city.valid?
  end

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
