require "test_helper"

class SuperAdminNotificationsControllerTest < ActionDispatch::IntegrationTest
  test "super admin sees notifications in the left menu and inbox" do
    super_admin = User.create!(name: "Super Admin", email: "notifications-admin@example.test", password: "password123", role: :super_admin)
    owner = User.create!(name: "Academy Owner", email: "notifications-owner@example.test", password: "password123", role: :parent)
    academy = Academy.create!(name: "Pending Academy", city: "Pune", owner: owner, status: :pending)
    notification = SuperAdminNotification.notify!(kind: :academy_submission, notifiable: academy, actor: owner)
    sign_in_as super_admin

    get root_path

    assert_response :success
    assert_includes response.body, super_admin_notifications_path
    assert_includes response.body, "Notifications"

    get super_admin_notifications_path

    assert_response :success
    assert_includes response.body, "Super admin notifications"
    assert_includes response.body, "Academy approval needed"
    assert_includes response.body, "Pending Academy"
    assert_includes response.body, approve_super_admin_notification_path(notification)
    assert_includes response.body, reject_super_admin_notification_path(notification)
    assert_includes response.body, dismiss_super_admin_notification_path(notification)
  end

  test "non super admin cannot open super admin notifications" do
    user = User.create!(name: "Normal User", email: "normal-notifications@example.test", password: "password123", role: :parent)
    sign_in_as user

    get super_admin_notifications_path

    assert_response :not_found
  end

  test "academy submission creates super admin notification and can be approved from inbox" do
    super_admin = User.create!(name: "Super Admin", email: "academy-approval-admin@example.test", password: "password123", role: :super_admin)
    owner = User.create!(name: "Academy Owner", email: "academy-approval-owner@example.test", password: "password123", role: :parent)
    sign_in_as owner

    assert_difference("SuperAdminNotification.academy_submission.pending.count", 1) do
      post academies_path, params: {
        academy: {
          name: "Review Queue Academy",
          city: "Pune",
          email: "review-queue@example.test"
        }.merge(consent_params)
      }
    end

    academy = Academy.order(:created_at).last
    notification = SuperAdminNotification.academy_submission.pending.find_by!(notifiable: academy)
    assert_equal owner, notification.actor
    assert_predicate academy, :pending?

    sign_in_as super_admin
    patch approve_super_admin_notification_path(notification)

    assert_redirected_to super_admin_notifications_path
    assert_predicate notification.reload, :approved?
    assert_predicate academy.reload, :approved?
    assert_predicate owner.reload, :academy_owner?

    get super_admin_notifications_path
    assert_response :success
    assert_not_includes response.body, "Review Queue Academy"
  end

  test "registered academy athlete request goes only to academy notification queue" do
    owner = User.create!(name: "Academy Owner", email: "registered-routing-owner@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Registered Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "registered-routing-athlete@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as athlete_user

    assert_difference("AcademyMembershipRequest.pending.count", 1) do
      assert_no_difference("SuperAdminNotification.unregistered_academy_athlete.pending.count") do
        patch athlete_path(athlete), params: {
          athlete: {
            first_name: "Aarohi",
            last_name: "Shah",
            date_of_birth: Date.new(2014, 5, 12),
            gender: "female",
            academy_id: academy.id
          }
        }
      end
    end
  end

  test "unregistered academy athlete creates super admin notification and rejection clears external academy" do
    super_admin = User.create!(name: "Super Admin", email: "external-routing-admin@example.test", password: "password123", role: :super_admin)
    athlete_user = User.create!(name: "Athlete User", email: "external-routing-athlete@example.test", phone: "9876543210", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as athlete_user

    assert_difference("SuperAdminNotification.unregistered_academy_athlete.pending.count", 1) do
      assert_no_difference("AcademyMembershipRequest.count") do
        patch athlete_path(athlete), params: {
          athlete: {
            first_name: "Aarohi",
            last_name: "Shah",
            date_of_birth: Date.new(2014, 5, 12),
            gender: "female",
            academy_id: "other",
            external_academy_name: "Independent Dojang"
          }
        }
      end
    end

    notification = SuperAdminNotification.unregistered_academy_athlete.pending.find_by!(notifiable: athlete)
    assert_equal athlete_user, notification.actor

    sign_in_as super_admin
    get super_admin_notifications_path
    assert_response :success
    assert_includes response.body, "Unregistered academy review"
    assert_includes response.body, "Independent Dojang"

    patch reject_super_admin_notification_path(notification)

    assert_redirected_to super_admin_notifications_path
    assert_predicate notification.reload, :rejected?
    assert_nil athlete.reload.external_academy_name

    get super_admin_notifications_path
    assert_response :success
    assert_not_includes response.body, "Independent Dojang"
  end

  test "tournament creation creates super admin notification and can be marked reviewed" do
    super_admin = User.create!(name: "Super Admin", email: "tournament-review-admin@example.test", password: "password123", role: :super_admin)
    organizer = User.create!(name: "Organizer", email: "tournament-review-organizer@example.test", password: "password123", role: :organizer, organizer_status: :verified)
    sign_in_as organizer

    assert_difference("SuperAdminNotification.tournament_submission.pending.count", 1) do
      post tournaments_path, params: {
        tournament: {
          name: "Review Queue Open",
          start_date: Date.new(2026, 12, 5),
          end_date: Date.new(2026, 12, 6),
          registration_opens_at: 2.days.from_now,
          registration_closes_at: 4.days.from_now,
          status: "draft"
        }.merge(consent_params)
      }
    end

    tournament = Tournament.order(:created_at).last
    notification = SuperAdminNotification.tournament_submission.pending.find_by!(notifiable: tournament)
    assert_equal organizer, notification.actor

    sign_in_as super_admin
    get super_admin_notifications_path
    assert_response :success
    assert_includes response.body, "New tournament created"
    assert_includes response.body, "Review Queue Open"
    assert_includes response.body, "Mark reviewed"

    patch approve_super_admin_notification_path(notification)

    assert_redirected_to super_admin_notifications_path
    assert_predicate notification.reload, :reviewed?

    get super_admin_notifications_path
    assert_response :success
    assert_not_includes response.body, "Review Queue Open"
  end
end
