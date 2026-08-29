require "test_helper"

class TournamentDrawGeneratorTest < ActiveSupport::TestCase
  setup do
    @organizer = User.create!(name: "Organizer", email: "draw-organizer@example.test", password: "password123", role: :organizer)
    @tournament = Tournament.create!(
      name: "Draw Open",
      organizer: @organizer,
      status: :registration_open,
      registration_opens_at: 10.days.ago,
      registration_closes_at: 1.day.ago,
      start_date: 2.days.from_now.to_date,
      end_date: 3.days.from_now.to_date
    )
    @category = @tournament.tournament_categories.create!(
      event_type: "kyorugi",
      gender: "female",
      age_min: 12,
      age_max: 14,
      weight_min: 33,
      weight_max: 37
    )
  end

  test "generates minimum bye bracket and avoids same academy in first round when possible" do
    first_academy = Academy.create!(name: "First Academy", city: "Pune", status: :approved)
    second_academy = Academy.create!(name: "Second Academy", city: "Mumbai", status: :approved)
    create_draw_registration("Aarohi", "Shah", first_academy)
    create_draw_registration("Anaya", "Iyer", first_academy)
    create_draw_registration("Meera", "Rao", second_academy)
    create_draw_registration("Tara", "Nair", second_academy)
    create_draw_registration("Zoya", "Kapoor", second_academy)

    result = TournamentDrawGenerator.new(tournament: @tournament, generated_by: @organizer).call

    assert_equal 1, result.draws.size
    draw = result.draws.first
    assert_equal 8, draw.bracket_size
    assert_equal 3, draw.round_count
    assert_equal 5, draw.entry_count
    assert_equal 7, draw.tournament_draw_matches.count
    assert_equal 3, draw.tournament_draw_matches.where(round_number: 1, bye: true).count

    first_round_matches = draw.tournament_draw_matches.where(round_number: 1, bye: false)
    assert first_round_matches.all? { |match| match.red_registration.athlete.academy_id != match.blue_registration.athlete.academy_id }
  end

  test "does not overwrite an existing draw" do
    create_draw_registration("Aarohi", "Shah", nil)
    create_draw_registration("Meera", "Rao", nil)

    first_result = TournamentDrawGenerator.new(tournament: @tournament, generated_by: @organizer).call
    second_result = TournamentDrawGenerator.new(tournament: @tournament, generated_by: @organizer).call

    assert_equal 1, first_result.draws.size
    assert_equal 0, second_result.draws.size
    assert_equal [first_result.draws.first], second_result.existing_draws
    assert_equal 1, @tournament.tournament_draws.count
  end

  test "skips categories with fewer than two draw ready athletes" do
    create_draw_registration("Aarohi", "Shah", nil)

    result = TournamentDrawGenerator.new(tournament: @tournament, generated_by: @organizer).call

    assert_empty result.draws
    assert_equal [@category], result.skipped_categories
    assert_empty @tournament.tournament_draws
  end

  private

  def create_draw_registration(first_name, last_name, academy)
    user = User.create!(
      name: "#{first_name} #{last_name}",
      email: "#{first_name.downcase}-#{last_name.downcase}@example.test",
      password: "password123",
      role: :athlete
    )
    athlete = user.athletes.create!(
      academy: academy,
      first_name: first_name,
      last_name: last_name,
      date_of_birth: Date.new(2014, 5, 12),
      gender: "female"
    )
    @tournament.registrations.create!(
      athlete: athlete,
      tournament_category: @category,
      status: :weight_verified,
      payment_receipt: payment_receipt_upload
    )
  end
end
