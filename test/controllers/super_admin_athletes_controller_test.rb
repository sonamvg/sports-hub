require "test_helper"

class SuperAdminAthletesControllerTest < ActionDispatch::IntegrationTest
  test "super admin can see athlete menu item and all athletes" do
    first_user = User.create!(name: "First Parent", email: "admin-athlete-first@example.test", password: "password123", role: :parent)
    second_user = User.create!(name: "Second Parent", email: "admin-athlete-second@example.test", password: "password123", role: :parent)
    academy = Academy.create!(name: "Admin View Academy", city: "Pune", status: :approved)
    first_athlete = first_user.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", belt: "red", weight: 39.5)
    second_athlete = second_user.athletes.create!(first_name: "Vihaan", last_name: "Mehta", date_of_birth: Date.new(2013, 7, 2), gender: "male")
    super_admin = User.create!(name: "Super Admin", email: "super-admin-athletes@example.test", password: "password123", role: :super_admin)
    sign_in_as super_admin

    get root_path

    assert_response :success
    assert_includes response.body, super_admin_athletes_path
    assert_includes response.body, "Athlete"

    get super_admin_athletes_path

    assert_response :success
    assert_includes response.body, "Super admin athletes"
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, "Vihaan Mehta"
    assert_includes response.body, "Admin View Academy"
    assert_includes response.body, first_user.email
    assert_includes response.body, second_user.email
    assert_includes response.body, athlete_path(first_athlete)
    assert_includes response.body, super_admin_athlete_path(first_athlete)
    assert_includes response.body, "Are you sure you want to delete Aarohi Shah?"
    assert_includes response.body, "Delete athlete"
  end

  test "super admin can search athletes by name, academy, or email" do
    first_user = User.create!(name: "First Parent", email: "search-admin-athlete-first@example.test", password: "password123", role: :parent)
    second_user = User.create!(name: "Second Parent", email: "search-admin-athlete-second@example.test", password: "password123", role: :parent)
    academy = Academy.create!(name: "Search Admin Academy", city: "Pune", status: :approved)
    first_user.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    second_user.athletes.create!(first_name: "Vihaan", last_name: "Mehta", date_of_birth: Date.new(2013, 7, 2), gender: "male")
    super_admin = User.create!(name: "Super Admin", email: "search-super-admin-athletes@example.test", password: "password123", role: :super_admin)
    sign_in_as super_admin

    get super_admin_athletes_path(q: "aarohi")

    assert_response :success
    assert_includes response.body, "Aarohi Shah"
    assert_not_includes response.body, "Vihaan Mehta"

    get super_admin_athletes_path(q: "search admin academy")

    assert_response :success
    assert_includes response.body, "Aarohi Shah"
    assert_not_includes response.body, "Vihaan Mehta"

    get super_admin_athletes_path(q: "no-such-athlete")

    assert_response :success
    assert_includes response.body, "No athletes found"
  end

  test "non super admin cannot see super admin athlete page" do
    user = User.create!(name: "Normal User", email: "normal-admin-athletes@example.test", password: "password123", role: :parent)
    sign_in_as user

    get super_admin_athletes_path

    assert_response :not_found
  end

  test "super admin can export all athletes as csv" do
    parent = User.create!(name: "Export Parent", email: "athlete-export-parent@example.test", password: "password123", role: :parent)
    academy = Academy.create!(name: "Export Athlete Academy", city: "Pune", status: :approved)
    athlete = parent.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    super_admin = User.create!(name: "Super Admin", email: "athlete-export-admin@example.test", password: "password123", role: :super_admin)
    sign_in_as super_admin

    get export_super_admin_athletes_path

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, athlete.first_name
    assert_includes response.body, athlete.last_name
    assert_includes response.body, "Export Athlete Academy"
    assert_includes response.body, parent.email
  end

  test "non super admin cannot export athletes" do
    user = User.create!(name: "Normal User", email: "normal-athlete-export@example.test", password: "password123", role: :parent)
    sign_in_as user

    get export_super_admin_athletes_path

    assert_response :not_found
  end

  test "super admin can delete athlete from super admin page" do
    first_user = User.create!(name: "First Parent", email: "delete-admin-athlete-first@example.test", password: "password123", role: :parent)
    second_user = User.create!(name: "Second Parent", email: "delete-admin-athlete-second@example.test", password: "password123", role: :parent)
    first_athlete = first_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    second_athlete = second_user.athletes.create!(first_name: "Vihaan", last_name: "Mehta", date_of_birth: Date.new(2013, 7, 2), gender: "male")
    super_admin = User.create!(name: "Super Admin", email: "delete-super-admin-athletes@example.test", password: "password123", role: :super_admin)
    sign_in_as super_admin

    assert_difference("Athlete.count", -1) do
      delete super_admin_athlete_path(first_athlete)
    end

    assert_redirected_to super_admin_athletes_path
    assert_equal "Athlete profile removed.", flash[:notice]
    assert_not Athlete.exists?(first_athlete.id)
    assert Athlete.exists?(second_athlete.id)
  end

  test "super admin deleting an athlete with match history anonymizes instead of crashing" do
    parent = User.create!(name: "History Parent", email: "super-admin-history-parent@example.test", password: "password123", role: :parent)
    athlete = parent.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", contact_number: "9123456789")
    organizer = User.create!(name: "History Organizer", email: "super-admin-history-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "History Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.create!(event_type: "kyorugi", gender: "female", age_min: 10, age_max: 16)
    minimal_png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
    receipt = -> { { io: StringIO.new(minimal_png), filename: "receipt.png", content_type: "image/png" } }
    registration = Registration.create!(tournament: tournament, athlete: athlete, tournament_category: category, status: :weight_verified, payment_receipt: receipt.call)
    opponent_user = User.create!(name: "History Opponent", email: "super-admin-history-opponent@example.test", password: "password123", role: :parent)
    opponent_athlete = opponent_user.athletes.create!(first_name: "Riya", last_name: "Patil", date_of_birth: Date.new(2014, 3, 3), gender: "female")
    opponent_registration = Registration.create!(tournament: tournament, athlete: opponent_athlete, tournament_category: category, status: :weight_verified, payment_receipt: receipt.call)
    Match.create!(tournament_category: category, round_number: 1, slot_position: 1, registration_one: registration, registration_two: opponent_registration)
    super_admin = User.create!(name: "Super Admin", email: "super-admin-history-admin@example.test", password: "password123", role: :super_admin)
    sign_in_as super_admin

    assert_no_difference("Athlete.count") do
      delete super_admin_athlete_path(athlete)
    end

    assert_redirected_to super_admin_athletes_path
    assert_equal "This athlete has match history that must be preserved, so their profile was anonymized instead of removed.", flash[:notice]
    athlete.reload
    assert_equal "Aarohi", athlete.first_name
    assert_nil athlete.contact_number
    assert Match.exists?(registration_one_id: registration.id)
  end
end
