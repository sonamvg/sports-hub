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
end
