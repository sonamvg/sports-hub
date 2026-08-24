require "test_helper"

class AcademiesControllerTest < ActionDispatch::IntegrationTest
  test "creates academy submission owned by current user" do
    owner = User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :parent)
    sign_in_as owner

    assert_difference("Academy.count", 1) do
      post academies_path, params: {
        academy: {
          name: "Deccan Taekwondo Academy",
          city: "Pune",
          email: "deccan@example.com"
        }
      }
    end

    academy = Academy.order(:created_at).last
    assert_equal owner, academy.owner
    assert_predicate academy, :pending?
    assert_redirected_to academy_path(academy)
    assert_equal "Academy submitted for super admin approval.", flash[:notice]
  end

  test "super admin approves academy and promotes owner" do
    super_admin = User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :super_admin)
    owner = User.create!(name: "Academy Owner", email: "owner@example.test", password: "password123", role: :parent)
    academy = Academy.create!(name: "Pending Academy", city: "Pune", owner: owner, status: :pending)
    sign_in_as super_admin

    patch approve_academy_path(academy)

    assert_redirected_to academy_path(academy)
    assert_predicate academy.reload, :approved?
    assert_not_nil academy.reviewed_at
    assert_predicate owner.reload, :academy_owner?
    assert_predicate super_admin, :super_admin?
  end

  test "public index hides pending academies from normal users" do
    User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :parent)
    approved = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved)
    pending = Academy.create!(name: "Pending Academy", city: "Mumbai", status: :pending)

    get academies_path

    assert_response :success
    assert_includes response.body, approved.name
    assert_not_includes response.body, pending.name
  end

  test "logged out index hides academy athlete counts" do
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved)
    parent = User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :parent)
    parent.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")

    get academies_path

    assert_response :success
    assert_includes response.body, academy.name
    assert_not_includes response.body, "1 athlete"
  end

  test "logged out show hides registered athlete details" do
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved)
    parent = User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :parent)
    parent.athletes.create!(
      academy: academy,
      first_name: "Aarohi",
      last_name: "Shah",
      date_of_birth: Date.new(2014, 5, 12),
      gender: "female",
      belt: "red"
    )

    get academy_path(academy)

    assert_response :success
    assert_includes response.body, academy.name
    assert_not_includes response.body, "Registered athletes"
    assert_not_includes response.body, "Aarohi Shah"
    assert_not_includes response.body, "Red"
  end

  test "academy manager can see registered athlete details" do
    owner = User.create!(name: "Academy Owner", email: "owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved, owner: owner)
    owner.athletes.create!(
      academy: academy,
      first_name: "Aarohi",
      last_name: "Shah",
      date_of_birth: Date.new(2014, 5, 12),
      gender: "female",
      belt: "red"
    )
    sign_in_as owner

    get academy_path(academy)

    assert_response :success
    assert_includes response.body, "Registered athletes"
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, "Red"
  end
end
