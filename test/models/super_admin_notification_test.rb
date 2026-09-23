require "test_helper"

class SuperAdminNotificationTest < ActiveSupport::TestCase
  test "destroying a tournament removes its super admin notifications" do
    organizer = User.create!(name: "Organizer", email: "notification-tournament-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Notification Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    notification = SuperAdminNotification.notify!(kind: :tournament_submission, notifiable: tournament, actor: organizer)

    tournament.destroy!

    assert_not SuperAdminNotification.exists?(notification.id)
  end

  test "destroying an academy removes its super admin notifications" do
    owner = User.create!(name: "Academy Owner", email: "notification-academy-owner@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Notification Academy", city: "Hyderabad", owner: owner)
    notification = SuperAdminNotification.notify!(kind: :academy_submission, notifiable: academy, actor: owner)

    academy.destroy!

    assert_not SuperAdminNotification.exists?(notification.id)
  end

  test "destroying an athlete removes its super admin notifications" do
    athlete_user = User.create!(name: "Athlete User", email: "notification-athlete-user@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Reddy", date_of_birth: Date.new(2015, 6, 15), gender: "female")
    notification = SuperAdminNotification.notify!(kind: :unregistered_academy_athlete, notifiable: athlete, actor: athlete_user)

    athlete.destroy!

    assert_not SuperAdminNotification.exists?(notification.id)
  end
end
