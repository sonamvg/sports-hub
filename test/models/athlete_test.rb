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

  test "rejects an invalid profile photo URL and accepts a valid one" do
    athlete = @user.athletes.build(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", profile_photo_url: "not-a-url")

    assert_not athlete.valid?
    assert_includes athlete.errors[:profile_photo_url], "must be a valid http or https URL"

    athlete.profile_photo_url = "https://example.com/photo.jpg"
    athlete.valid?
    assert_empty athlete.errors[:profile_photo_url]
  end

  test "profile photo source prefers the uploaded photo over the URL" do
    athlete = @user.athletes.build(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", profile_photo_url: "https://example.com/photo.jpg")
    assert_equal "https://example.com/photo.jpg", athlete.profile_photo_source

    minimal_png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
    athlete.profile_photo.attach(io: StringIO.new(minimal_png), filename: "profile.png", content_type: "image/png")
    assert_equal athlete.profile_photo, athlete.profile_photo_source
  end

  test "profile is not complete for registration until a contact number is set" do
    athlete = @user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    assert_not athlete.profile_complete_for_registration?

    athlete.contact_number = "9123456789"
    assert athlete.profile_complete_for_registration?
  end

  test "rejects zero, negative, non-numeric, and out-of-range weight" do
    base = { first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female" }

    zero = @user.athletes.build(base.merge(weight: 0))
    assert_not zero.valid?
    assert_includes zero.errors[:weight], "must be greater than 0"

    negative = @user.athletes.build(base.merge(weight: -5))
    assert_not negative.valid?
    assert_includes negative.errors[:weight], "must be greater than 0"

    non_numeric = @user.athletes.build(base.merge(weight: "abc"))
    assert_not non_numeric.valid?
    assert_includes non_numeric.errors[:weight], "is not a number"

    too_large = @user.athletes.build(base.merge(weight: 1000))
    assert_not too_large.valid?
    assert_includes too_large.errors[:weight], "must be less than or equal to 999.99"

    valid = @user.athletes.build(base.merge(weight: 55.5))
    assert valid.valid?
  end

  test "rejects a city containing digits and a state outside the Indian states list" do
    athlete = @user.athletes.build(
      first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female",
      city: "Pune123", state: "Telaanga"
    )

    assert_not athlete.valid?
    assert_includes athlete.errors[:city], "can only contain letters, spaces, hyphens, and apostrophes"
    assert_includes athlete.errors[:state], "is not included in the list"
  end

  test "rejects an emergency contact name containing digits" do
    athlete = @user.athletes.build(
      first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female",
      emergency_contact_name: "Priya2"
    )

    assert_not athlete.valid?
    assert_includes athlete.errors[:emergency_contact_name], "can only contain letters, spaces, hyphens, and apostrophes"
  end

  test "rejects an emergency contact name or phone that matches the athlete's own" do
    athlete = @user.athletes.build(
      first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female",
      contact_number: "9123456789",
      emergency_contact_name: "aarohi shah",
      emergency_contact_phone: "9123456789"
    )

    assert_not athlete.valid?
    assert_includes athlete.errors[:emergency_contact_name], "cannot be the same as the athlete's own name"
    assert_includes athlete.errors[:emergency_contact_phone], "cannot be the same as the athlete's own contact number"
  end

  test "accepts an emergency contact name and phone that differ from the athlete's own" do
    athlete = @user.athletes.build(
      first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female",
      contact_number: "9123456789",
      emergency_contact_name: "Priya Shah",
      emergency_contact_phone: "9988776655"
    )

    assert athlete.valid?
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

  test "rejects athlete profile uploads that are not jpg or png" do
    athlete = @user.athletes.build(
      first_name: "Aarohi",
      last_name: "Shah",
      date_of_birth: Date.new(2014, 5, 12),
      gender: "female"
    )
    athlete.profile_photo.attach(io: StringIO.new("not an image"), filename: "profile.txt", content_type: "text/plain")
    athlete.identity_documents.attach(io: StringIO.new("%PDF-1.4"), filename: "id.pdf", content_type: "application/pdf")

    assert_not athlete.valid?
    assert_includes athlete.errors[:profile_photo], "must be a JPG or PNG file"
    assert_includes athlete.errors[:identity_documents], "must be a JPG or PNG file"
  end

  test "rejects more identity documents than the allowed maximum" do
    athlete = @user.athletes.build(
      first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female"
    )
    minimal_png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
    (Athlete::MAX_IDENTITY_DOCUMENTS + 1).times do |index|
      athlete.identity_documents.attach(io: StringIO.new(minimal_png), filename: "id-#{index}.png", content_type: "image/png")
    end

    assert_not athlete.valid?
    assert_includes athlete.errors[:identity_documents], "cannot include more than #{Athlete::MAX_IDENTITY_DOCUMENTS} files"
  end

  test "accepts jpg and png athlete profile uploads under five megabytes" do
    athlete = @user.athletes.build(
      first_name: "Aarohi",
      last_name: "Shah",
      date_of_birth: Date.new(2014, 5, 12),
      gender: "female"
    )
    minimal_jpeg = Base64.decode64("/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAj/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=")
    minimal_png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
    athlete.profile_photo.attach(io: StringIO.new(minimal_jpeg), filename: "profile.jpg", content_type: "image/jpeg")
    athlete.identity_documents.attach(
      { io: StringIO.new(minimal_png), filename: "id-front.png", content_type: "image/png" },
      { io: StringIO.new(minimal_png), filename: "id-back.png", content_type: "image/png" }
    )

    assert_predicate athlete, :valid?
    assert_equal 2, athlete.identity_documents.size
  end
end
