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

  test "rejects an academy name that is only digits or symbols" do
    academy = Academy.new(name: "12345", city: "Pune")

    assert_not academy.valid?
    assert_includes academy.errors[:name], "must contain letters, and can include spaces, numbers, hyphens, and apostrophes"
  end

  test "accepts an academy name with letters, numbers, hyphens, and apostrophes" do
    academy = Academy.new(name: "Deccan Taekwondo Club No 5", city: "Pune")
    academy.valid?
    assert_empty academy.errors[:name]

    academy2 = Academy.new(name: "O'Brien's TKD - 24x7", city: "Mumbai")
    academy2.valid?
    assert_empty academy2.errors[:name]
  end

  test "rejects city, state, or country that is blank-looking or digits only" do
    academy = Academy.new(name: "Deccan Taekwondo Academy", city: "12345", state: "999", country: "000")

    assert_not academy.valid?
    assert_includes academy.errors[:city], "cannot be blank or numbers only"
    assert_includes academy.errors[:state], "cannot be blank or numbers only"
    assert_includes academy.errors[:country], "cannot be blank or numbers only"
  end

  test "approved academies are visible to public" do
    academy = Academy.new(name: "Deccan Taekwondo Academy", city: "Pune", status: :approved)

    assert academy.visible_to_public?
  end

  test "pending academies are not visible to public" do
    academy = Academy.new(name: "Deccan Taekwondo Academy", city: "Pune", status: :pending)

    assert_not academy.visible_to_public?
  end

  test "rejects a placeholder or example email domain" do
    academy = Academy.new(name: "Deccan Taekwondo Academy", city: "Pune", email: "contact@example.com")

    assert_not academy.valid?
    assert_includes academy.errors[:email], "must be a real email address, not a placeholder or test domain"
  end

  test "academy logo must be jpg or png" do
    academy = Academy.new(name: "Deccan Taekwondo Academy", city: "Pune")
    academy.logo_image.attach(io: StringIO.new("%PDF-1.4"), filename: "logo.pdf", content_type: "application/pdf")

    assert_not academy.valid?
    assert_includes academy.errors[:logo_image], "file size should be less than 5 MB and PNG/JPG is accepted"
  end
end
