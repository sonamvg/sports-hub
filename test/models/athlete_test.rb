require "test_helper"

class AthleteTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: "Parent", email: "parent@example.test", password: "password123", role: :parent)
  end

  test "normalizes profile fields before validation" do
    athlete = @user.athletes.create!(
      first_name: "  aarohi  ",
      last_name: "  shah  ",
      date_of_birth: Date.new(2014, 5, 12),
      gender: "FEMALE",
      belt: "RED",
      association_id: "  TKD-123  ",
      city: "  Pune  ",
      state: " Maharashtra ",
      country: ""
    )

    assert_equal "aarohi", athlete.first_name
    assert_equal "shah", athlete.last_name
    assert_equal "female", athlete.gender
    assert_equal "red", athlete.belt
    assert_equal "TKD-123", athlete.association_id
    assert_equal "Pune", athlete.city
    assert_equal "Maharashtra", athlete.state
    assert_equal "India", athlete.country
    assert_equal "aarohi shah", athlete.full_name
  end

  test "rejects future date of birth" do
    athlete = @user.athletes.build(
      first_name: "Aarohi",
      last_name: "Shah",
      date_of_birth: 1.day.from_now.to_date,
      gender: "female"
    )

    assert_not athlete.valid?
    assert_includes athlete.errors[:date_of_birth], "cannot be in the future"
  end

  test "rejects unsupported gender and belt values" do
    athlete = @user.athletes.build(
      first_name: "Aarohi",
      last_name: "Shah",
      date_of_birth: Date.new(2014, 5, 12),
      gender: "unknown",
      belt: "purple"
    )

    assert_not athlete.valid?
    assert_includes athlete.errors[:gender], "is not included in the list"
    assert_includes athlete.errors[:belt], "is not included in the list"
  end

  test "rejects pending academy assignment" do
    academy = Academy.create!(name: "Pending Academy", city: "Pune", status: :pending)
    athlete = @user.athletes.build(
      academy: academy,
      first_name: "Aarohi",
      last_name: "Shah",
      date_of_birth: Date.new(2014, 5, 12),
      gender: "female"
    )

    assert_not athlete.valid?
    assert_includes athlete.errors[:academy], "must be approved before athletes can be assigned"
  end
end
