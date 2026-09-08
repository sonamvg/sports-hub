require "test_helper"

class OrganizerRegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "organizer sees only registrations for owned tournaments" do
    organizer = User.create!(name: "Demo Parent", email: "parent@example.test", password: "password123", role: :organizer)
    other_organizer = User.create!(name: "Other Organizer", email: "other-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "athlete-user@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")

    owned_tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    owned_category = owned_tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    owned_registration = owned_tournament.registrations.create!(athlete: athlete, tournament_category: owned_category, payment_receipt: payment_receipt_upload)

    other_tournament = Tournament.create!(name: "Other Open", organizer: other_organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    other_category = other_tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    other_tournament.registrations.create!(athlete: athlete, tournament_category: other_category, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    get organizer_registrations_path

    assert_response :success
    assert_includes response.body, owned_registration.tournament.name
    assert_not_includes response.body, other_tournament.name
  end

  test "scoping to a tournament id shows only that tournament's athletes" do
    organizer = User.create!(name: "Demo Parent", email: "scope-parent@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "scope-athlete-user@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")

    tournament_one = Tournament.create!(name: "Scoped One Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category_one = tournament_one.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    tournament_one.registrations.create!(athlete: athlete, tournament_category: category_one, payment_receipt: payment_receipt_upload)

    tournament_two = Tournament.create!(name: "Scoped Two Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category_two = tournament_two.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    tournament_two.registrations.create!(athlete: athlete, tournament_category: category_two, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    get organizer_registrations_path(tournament_id: tournament_one.id)

    assert_response :success
    content = main_content_html
    assert_includes content, "Scoped One Open"
    assert_not_includes content, "Scoped Two Open"
    assert_not_includes content, "<th>Tournament</th>"
  end

  test "an unrecognized tournament id falls back to the full list instead of leaking another organizer's tournament" do
    organizer = User.create!(name: "Demo Parent", email: "scope-fallback-parent@example.test", password: "password123", role: :organizer)
    other_organizer = User.create!(name: "Other Organizer", email: "scope-fallback-other@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "scope-fallback-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")

    other_tournament = Tournament.create!(name: "Not Yours Open", organizer: other_organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    other_category = other_tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    other_tournament.registrations.create!(athlete: athlete, tournament_category: other_category, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    get organizer_registrations_path(tournament_id: other_tournament.id)

    assert_response :success
    assert_not_includes response.body, "Not Yours Open"
  end

  test "registrations are ordered pending accepted denied and include receipt review actions" do
    organizer = User.create!(name: "Organizer", email: "ordering-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "ordering-athlete@example.test", password: "password123", role: :parent)
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    pending_category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    approved_category = tournament.tournament_categories.find_or_create_by!(event_type: "poomsae", gender: "female", age_min: 12, age_max: 14)
    rejected_category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_max: 45)
    pending_athlete = athlete_user.athletes.create!(first_name: "Pending", last_name: "Athlete", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    approved_athlete = athlete_user.athletes.create!(first_name: "Accepted", last_name: "Athlete", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    rejected_athlete = athlete_user.athletes.create!(first_name: "Denied", last_name: "Athlete", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    tournament.registrations.create!(athlete: approved_athlete, tournament_category: approved_category, status: :approved, payment_receipt: payment_receipt_upload)
    tournament.registrations.create!(athlete: rejected_athlete, tournament_category: rejected_category, status: :rejected, payment_receipt: payment_receipt_upload)
    tournament.registrations.create!(athlete: pending_athlete, tournament_category: pending_category, status: :pending, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    get organizer_registrations_path

    assert_response :success
    assert_includes response.body, "organizer-registration-table"
    assert_includes response.body, "<table>"
    assert_includes response.body, "<th>Athlete</th>"
    assert_includes response.body, "<th>Tournament</th>"
    assert_includes response.body, "<th>Category</th>"
    assert_includes response.body, "<th>Status</th>"
    assert_includes response.body, "<th>Receipt</th>"
    assert_includes response.body, "receipt-action-link"
    assert_includes response.body, "kebab-menu"
    assert_includes response.body, "View receipt"
    assert_includes response.body, "Accept"
    assert_includes response.body, "Deny"
    assert_operator response.body.index("Pending Athlete"), :<, response.body.index("Accepted Athlete")
    assert_operator response.body.index("Accepted Athlete"), :<, response.body.index("Denied Athlete")
  end

  test "organizer can approve a registration whose receipt predates stricter content-type validation" do
    organizer = User.create!(name: "Organizer", email: "legacy-receipt-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "legacy-receipt-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    registration = tournament.registrations.build(athlete: athlete, tournament_category: category)
    registration.payment_receipt.attach(io: StringIO.new("not a real image"), filename: "receipt.png", content_type: "image/png")
    registration.save!(validate: false)
    sign_in_as organizer

    patch approve_organizer_registration_path(registration)

    assert_redirected_to organizer_registrations_path
    assert_equal "Registration accepted.", flash[:notice]
    assert_predicate registration.reload, :approved?
  end

  test "organizer accepting registration creates action log" do
    organizer = User.create!(name: "Organizer", email: "accept-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "accept-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    assert_difference("RegistrationActionLog.count", 1) do
      patch approve_organizer_registration_path(registration)
    end

    assert_redirected_to organizer_registrations_path
    assert_predicate registration.reload, :approved?
    log = registration.registration_action_logs.sole
    assert_equal organizer, log.actor
    assert_equal "approved", log.action
    assert_equal "pending", log.from_status
    assert_equal "approved", log.to_status
  end

  test "approving an already reviewed registration does not change its status again" do
    organizer = User.create!(name: "Organizer", email: "double-review-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "double-review-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    patch reject_organizer_registration_path(registration)
    assert_predicate registration.reload, :rejected?

    assert_no_difference("RegistrationActionLog.count") do
      patch approve_organizer_registration_path(registration)
    end

    assert_redirected_to organizer_registrations_path
    assert_equal "Registration has already been reviewed.", flash[:alert]
    assert_predicate registration.reload, :rejected?
  end

  test "super admin only sees action log when assigned to the tournament" do
    organizer = User.create!(name: "Organizer", email: "log-organizer@example.test", password: "password123", role: :organizer)
    super_admin = User.create!(name: "Super Admin", email: "log-admin@example.test", password: "password123", role: :super_admin)
    athlete_user = User.create!(name: "Athlete User", email: "log-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    tournament.tournament_organizers.create!(user: super_admin, added_by: organizer)
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)
    registration.review!(actor: organizer, status: :rejected)

    sign_in_as organizer
    get organizer_registration_path(registration)
    assert_response :success
    assert_not_includes response.body, "Action log"

    sign_in_as super_admin
    get organizer_registration_path(registration)
    assert_response :success
    assert_includes response.body, "Action log"
    assert_includes response.body, "Organizer"
    assert_includes response.body, "Pending → Rejected"
  end

  test "unassigned super admin is not the approval recipient for tournament registrations" do
    organizer = User.create!(name: "Organizer", email: "approval-owner@example.test", password: "password123", role: :organizer)
    super_admin = User.create!(name: "Super Admin", email: "approval-admin@example.test", password: "password123", role: :super_admin)
    athlete_user = User.create!(name: "Athlete User", email: "approval-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)
    sign_in_as super_admin

    get organizer_registrations_path
    assert_response :success
    assert_not_includes response.body, "Aarohi Shah"

    patch approve_organizer_registration_path(registration)
    assert_response :not_found
    assert_predicate registration.reload, :pending?
  end

  test "organizer can view a receipt through the authenticated controller action" do
    organizer = User.create!(name: "Organizer", email: "receipt-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "receipt-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    get organizer_registrations_path
    assert_response :success
    assert_includes response.body, receipt_organizer_registration_path(registration)
    assert_not_includes response.body, "rails/active_storage"

    get receipt_organizer_registration_path(registration)
    assert_response :success
    assert_equal "image/png", response.media_type
  end

  test "organizer cannot view a receipt for a registration outside their tournaments" do
    organizer = User.create!(name: "Organizer", email: "outside-receipt-organizer@example.test", password: "password123", role: :organizer)
    other_organizer = User.create!(name: "Other Organizer", email: "other-receipt-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "outside-receipt-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    other_tournament = Tournament.create!(name: "Other Open", organizer: other_organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = other_tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    registration = other_tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    get receipt_organizer_registration_path(registration)
    assert_response :not_found
  end

  test "registrations submitted together show a grouped payment total" do
    organizer = User.create!(name: "Organizer", email: "batch-total-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "batch-total-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(
      name: "Owned Open", organizer: organizer, registration_fee: 500, currency: "INR",
      payment_account_name: "Association", payment_bank_name: "Demo Bank", payment_account_number: "1234567890", payment_ifsc: "DEMO0001234",
      start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6)
    )
    category_one = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    category_two = tournament.tournament_categories.find_or_create_by!(event_type: "poomsae", gender: "female", age_min: 12, age_max: 14)
    batch_id = SecureRandom.uuid
    tournament.registrations.create!(athlete: athlete, tournament_category: category_one, fee_amount: 500, fee_currency: "INR", submission_batch_id: batch_id, payment_receipt: payment_receipt_upload)
    tournament.registrations.create!(athlete: athlete, tournament_category: category_two, fee_amount: 500, fee_currency: "INR", submission_batch_id: batch_id, payment_receipt: payment_receipt_upload)
    sign_in_as organizer

    get organizer_registrations_path

    assert_response :success
    assert_includes response.body, "INR 1000"
    assert_includes response.body, "Total for 2 categories submitted together"
  end

  test "cannot approve or reject a registration once its tournament is cancelled" do
    organizer = User.create!(name: "Organizer", email: "cancelled-review-organizer@example.test", password: "password123", role: :organizer)
    athlete_user = User.create!(name: "Athlete User", email: "cancelled-review-athlete@example.test", password: "password123", role: :parent)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    tournament = Tournament.create!(name: "Owned Open", organizer: organizer, start_date: Date.new(2026, 12, 5), end_date: Date.new(2026, 12, 6))
    category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41)
    registration = tournament.registrations.create!(athlete: athlete, tournament_category: category, payment_receipt: payment_receipt_upload)
    tournament.update!(status: :cancelled)
    sign_in_as organizer

    patch approve_organizer_registration_path(registration)

    assert_redirected_to organizer_registrations_path
    assert_equal "This registration can no longer be reviewed because the tournament has been cancelled.", flash[:alert]
    assert_predicate registration.reload, :pending?
  end

  private

  # The sidebar always lists every tournament the organizer manages, regardless
  # of which one the current page is scoped to, so assertions about scoping
  # need to look only at the main content area and ignore the sidebar.
  def main_content_html
    doc = Nokogiri::HTML::Document.parse(response.body)
    doc.css(".app-content").to_s
  end
end
