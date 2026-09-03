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

  test "non super admin cannot see super admin athlete page" do
    user = User.create!(name: "Normal User", email: "normal-admin-athletes@example.test", password: "password123", role: :parent)
    sign_in_as user

    get super_admin_athletes_path

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
end
