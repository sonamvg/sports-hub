require "test_helper"

class TournamentTest < ActiveSupport::TestCase
  test "end date cannot be before start date" do
    tournament = Tournament.new(name: "Test", start_date: Date.new(2026, 10, 2), end_date: Date.new(2026, 10, 1))
    assert_not tournament.valid?
    assert_includes tournament.errors[:end_date], "cannot be before start date"
  end

  test "registration close must be after open" do
    tournament = Tournament.new(
      name: "Pune Invitational",
      start_date: Date.new(2026, 10, 18),
      end_date: Date.new(2026, 10, 19),
      registration_opens_at: Time.zone.local(2026, 9, 10, 10, 0),
      registration_closes_at: Time.zone.local(2026, 9, 10, 9, 0)
    )

    assert_not tournament.valid?
    assert_includes tournament.errors[:registration_closes_at], "must be after registration opens at"
  end

  test "registration close cannot be after event start date" do
    tournament = Tournament.new(
      name: "Pune Invitational",
      start_date: Date.new(2026, 10, 18),
      end_date: Date.new(2026, 10, 19),
      registration_opens_at: Time.zone.local(2026, 9, 10, 10, 0),
      registration_closes_at: Time.zone.local(2026, 10, 19, 10, 0)
    )

    assert_not tournament.valid?
    assert_includes tournament.errors[:registration_closes_at], "cannot be after the event start date"
  end

  test "accepting registrations requires open status and active window" do
    tournament = Tournament.new(
      name: "Pune Invitational",
      status: :registration_open,
      start_date: Date.new(2026, 10, 18),
      end_date: Date.new(2026, 10, 19),
      registration_opens_at: Time.zone.local(2026, 9, 1, 10, 0),
      registration_closes_at: Time.zone.local(2026, 9, 30, 18, 0)
    )

    assert tournament.accepting_registrations?(at: Time.zone.local(2026, 9, 10, 12, 0))
    assert_not tournament.accepting_registrations?(at: Time.zone.local(2026, 10, 1, 12, 0))

    tournament.status = :registration_paused
    assert_not tournament.accepting_registrations?(at: Time.zone.local(2026, 9, 10, 12, 0))
  end
end
