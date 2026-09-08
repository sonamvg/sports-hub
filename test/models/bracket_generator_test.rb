require "test_helper"

class BracketGeneratorTest < ActiveSupport::TestCase
  setup do
    @organizer = User.create!(name: "Organizer", email: "bracket-organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(name: "Bracket Open", organizer: @organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    @category = @tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 18)
  end

  test "requires at least 2 weight-verified registrations" do
    create_weight_verified_registration(tournament: @tournament, category: @category, email: "solo@example.test")

    result = BracketGenerator.new(@category).call

    assert_not result.success?
    assert_match(/at least 2/i, result.error)
    assert_not @category.reload.draw_generated?
  end

  test "refuses to generate a draw for a cancelled tournament" do
    create_weight_verified_registration(tournament: @tournament, category: @category, email: "one@example.test")
    create_weight_verified_registration(tournament: @tournament, category: @category, email: "two@example.test")
    @tournament.update!(status: :cancelled)

    result = BracketGenerator.new(@category).call

    assert_not result.success?
    assert_match(/cancelled/i, result.error)
    assert_not @category.reload.draw_generated?
  end

  test "refuses to generate a draw while registration is still open" do
    @tournament.update!(registration_opens_at: 1.day.ago, registration_closes_at: 1.day.from_now)
    create_weight_verified_registration(tournament: @tournament, category: @category, email: "still-open-one@example.test")
    create_weight_verified_registration(tournament: @tournament, category: @category, email: "still-open-two@example.test")

    result = BracketGenerator.new(@category).call

    assert_not result.success?
    assert_match(/registration has closed/i, result.error)
    assert_not @category.reload.draw_generated?
  end

  test "allows generating a draw once registration has closed" do
    @tournament.update!(registration_opens_at: 10.days.ago, registration_closes_at: 1.day.ago)
    create_weight_verified_registration(tournament: @tournament, category: @category, email: "now-closed-one@example.test")
    create_weight_verified_registration(tournament: @tournament, category: @category, email: "now-closed-two@example.test")

    result = BracketGenerator.new(@category).call

    assert result.success?
    assert @category.reload.draw_generated?
  end

  test "refuses to regenerate an already-generated draw" do
    seed_registrations(3)
    BracketGenerator.new(@category).call

    result = BracketGenerator.new(@category).call

    assert_not result.success?
    assert_match(/already been set/i, result.error)
  end

  test "keeps clubmates apart in round 1 when the field allows it" do
    academy_one = Academy.create!(name: "Deccan Taekwondo Academy", city: "Pune", status: :approved)
    academy_two = Academy.create!(name: "Mumbai Falcons Taekwondo", city: "Mumbai", status: :approved)

    seed_registration_with_academy(email: "clubmate-a1@example.test", academy: academy_one)
    seed_registration_with_academy(email: "clubmate-a2@example.test", academy: academy_one)
    seed_registration_with_academy(email: "clubmate-b1@example.test", academy: academy_two)
    seed_registration_with_academy(email: "clubmate-b2@example.test", academy: academy_two)

    result = BracketGenerator.new(@category).call
    assert result.success?

    round_one_matches = @category.reload.matches.where(round_number: 1).includes(registration_one: :athlete, registration_two: :athlete)
    round_one_matches.each do |match|
      next unless match.registration_one && match.registration_two

      assert_not_equal match.registration_one.athlete.academy_id, match.registration_two.athlete.academy_id,
        "expected round 1 match to avoid pairing two athletes from the same academy"
    end
  end

  test "allows a same-academy pairing in round 1 only when unavoidable" do
    academy = Academy.create!(name: "Deccan Taekwondo Academy", city: "Pune", status: :approved)

    seed_registration_with_academy(email: "unavoidable-a1@example.test", academy: academy)
    seed_registration_with_academy(email: "unavoidable-a2@example.test", academy: academy)
    seed_registration_with_academy(email: "unavoidable-a3@example.test", academy: academy)

    result = BracketGenerator.new(@category).call
    assert result.success?
    assert_equal 3, @category.reload.matches.count
  end

  [ 2, 3, 4, 5, 6, 7, 8, 9, 11, 16 ].each do |count|
    test "builds a valid single-elimination bracket for #{count} entrants" do
      registrations = seed_registrations(count)

      result = BracketGenerator.new(@category).call
      assert result.success?, result.error

      @category.reload
      assert @category.draw_generated?

      matches = @category.matches.order(:round_number, :slot_position)
      bracket_size = 1
      bracket_size *= 2 while bracket_size < count
      rounds_count = Math.log2(bracket_size).to_i

      assert_equal rounds_count, matches.map(&:round_number).max

      # No round-1 match ever pairs two byes together.
      round_one = matches.select { |m| m.round_number == 1 }
      assert_equal bracket_size / 2, round_one.size
      round_one.each do |match|
        present = [ match.registration_one_id, match.registration_two_id ].compact
        assert present.size >= 1, "match #{match.slot_position} has no participant at all"
      end

      # Every real registration appears exactly once across round 1.
      seeded_ids = round_one.flat_map { |m| [ m.registration_one_id, m.registration_two_id ] }.compact
      assert_equal registrations.map(&:id).sort, seeded_ids.sort

      # Byes are already resolved and their winners advanced.
      byes = round_one.select(&:bye?)
      byes.each do |bye_match|
        assert bye_match.winner_registration_id.present?
        next_match = matches.find { |m| m.id == bye_match.next_match_id }
        next_match_ids = [ next_match.registration_one_id, next_match.registration_two_id ]
        assert_includes next_match_ids, bye_match.winner_registration_id
      end

      # The final round has exactly one match with no next_match.
      final_matches = matches.select { |m| m.next_match_id.nil? }
      assert_equal 1, final_matches.size
      assert_equal rounds_count, final_matches.first.round_number
    end
  end

  private

  def seed_registrations(count)
    count.times.map { |i| create_weight_verified_registration(tournament: @tournament, category: @category, email: "bracket-#{count}-#{i}@example.test") }
  end

  def seed_registration_with_academy(email:, academy:)
    parent = User.create!(name: "Parent #{email.split("@").first.gsub(/[^a-zA-Z]/, "").presence || "User"}", email: email, password: "password123", role: :parent)
    athlete = parent.athletes.create!(
      first_name: "Athlete",
      last_name: email.split("@").first.gsub(/[^a-zA-Z]/, "").presence || "User",
      date_of_birth: Date.new(1995, 1, 1),
      gender: "male",
      academy: academy
    )

    Registration.create!(
      tournament: @tournament,
      athlete: athlete,
      tournament_category: @category,
      status: :weight_verified,
      payment_receipt: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/payment-receipt.png"), "image/png")
    )
  end
end
