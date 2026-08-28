require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "new session page uses neutral welcome heading" do
    get login_path

    assert_response :success
    assert_includes response.body, "Welcome"
    assert_not_includes response.body, "Welcome back"
  end

  test "new session page uses organizer CTA when creating tournament" do
    get login_path(return_to: new_tournament_path)

    assert_response :success
    assert_includes response.body, "Sign in as an organizer"
    assert_includes response.body, "Sign in as organizer"
    assert_includes response.body, "Create organizer account"
    assert_not_includes response.body, "Join as athlete"
  end

  test "new session page uses academy owner CTA when registering academy" do
    get login_path(return_to: new_academy_path)

    assert_response :success
    assert_includes response.body, "Sign in as an academy owner"
    assert_includes response.body, "Sign in as academy owner"
    assert_includes response.body, "Create academy owner account"
    assert_not_includes response.body, "Join as athlete"
  end

  test "signs in with valid credentials" do
    user = User.create!(name: "Demo Super Admin", email: "admin@example.com", password: "password123", role: :super_admin)

    post login_path, params: { email: "ADMIN@example.com ", password: "password123" }

    assert_redirected_to tournaments_path
    assert_equal user.id, session[:user_id]
    assert_equal "Signed in as Demo Super Admin.", flash[:notice]

    follow_redirect!
    assert_includes response.body, 'data-auto-dismiss="5000"'
  end

  test "athlete sign in defaults to own profile" do
    user = User.create!(name: "Athlete User", email: "athlete-login@example.com", phone: "9876543210", password: "password123", role: :athlete)
    athlete = user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")

    post login_path, params: { email: "athlete-login@example.com", password: "password123" }

    assert_redirected_to athlete_path(athlete)
    assert_equal user.id, session[:user_id]
  end

  test "academy owner sign in defaults to academies page" do
    user = User.create!(name: "Academy Owner", email: "academy-login@example.com", phone: "9876543210", password: "password123", role: :academy_owner)

    post login_path, params: { email: "academy-login@example.com", password: "password123" }

    assert_redirected_to academies_path
    assert_equal user.id, session[:user_id]
  end

  test "rejects invalid credentials" do
    User.create!(name: "Demo Super Admin", email: "admin@example.com", password: "password123", role: :super_admin)

    post login_path, params: { email: "admin@example.com", password: "wrong" }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_includes response.body, "Invalid email or password."
    assert_includes response.body, "Join as athlete"
  end

  test "new session page hides registration links when signed in" do
    user = User.create!(name: "Signed In Organizer", email: "signed-in-organizer@example.com", password: "password123", role: :organizer, organizer_status: :verified)
    sign_in_as user

    get login_path(return_to: new_tournament_path)

    assert_response :success
    assert_includes response.body, "Sign in as organizer"
    assert_not_includes response.body, "Create organizer account"
    assert_not_includes response.body, "Create academy owner account"
    assert_not_includes response.body, "Join as athlete"
  end

  test "blank sign in submit asks user to sign in before continuing" do
    post login_path, params: { email: "", password: "", return_to: new_tournament_path }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_includes response.body, "Please sign in before continuing."
    assert_includes response.body, 'value="/tournaments/new"'
  end

  test "signs out" do
    user = User.create!(name: "Demo Parent", email: "parent@example.com", password: "password123", role: :parent)
    sign_in_as user

    delete logout_path

    assert_redirected_to root_path
    assert_nil session[:user_id]
  end
end
