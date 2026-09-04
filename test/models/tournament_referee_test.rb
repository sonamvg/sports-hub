require "test_helper"

class TournamentRefereeTest < ActiveSupport::TestCase
  setup do
    organizer = User.create!(name: "Organizer", email: "referee-model-organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(
      name: "Referee Model Open",
      organizer: organizer,
      start_date: Date.new(2026, 12, 5),
      end_date: Date.new(2026, 12, 6)
    )
  end

  test "normalizes referee details" do
    referee = @tournament.tournament_referees.create!(
      name: "  Meera  Rao  ",
      email: "  MEERA@EXAMPLE.TEST ",
      phone: " 9876543210 ",
      role: " center referee ",
      qualification: " national referee ",
      certification_id: " NR-102 ",
      affiliation: " Pune Association ",
      notes: " available all day "
    )

    assert_equal "Meera Rao", referee.name
    assert_equal "meera@example.test", referee.email
    assert_equal "9876543210", referee.phone
    assert_equal "center referee", referee.role
    assert_equal "national referee", referee.qualification
    assert_equal "NR-102", referee.certification_id
    assert_equal "Pune Association", referee.affiliation
    assert_equal "available all day", referee.notes
  end

  test "requires a valid email when provided" do
    referee = @tournament.tournament_referees.build(name: "Meera Rao", email: "not-an-email")

    assert_not referee.valid?
    assert_includes referee.errors[:email], "is invalid"
  end

  test "rejects a referee photo whose content does not match its declared image type" do
    referee = @tournament.tournament_referees.build(name: "Meera Rao")
    spoofed_upload = Rack::Test::UploadedFile.new(StringIO.new("PK\x03\x04" + ("x" * 50)), "image/png", original_filename: "photo.png")
    referee.photo.attach(spoofed_upload)

    assert_not referee.valid?
    assert_includes referee.errors[:photo], "must be a JPG, PNG, or WebP file"
  end

  test "accepts a genuine png referee photo" do
    referee = @tournament.tournament_referees.build(name: "Meera Rao")
    referee.photo.attach(tournament_image_upload)

    assert referee.valid?
  end
end
