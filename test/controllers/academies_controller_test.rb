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
          email: "deccan@example.com",
          logo_image: tournament_image_upload
        }.merge(consent_params)
      }
    end

    academy = Academy.order(:created_at).last
    assert_equal owner, academy.owner
    assert_predicate academy.logo_image, :attached?
    assert_predicate academy, :pending?
    assert_not_nil academy.terms_accepted_at
    assert_not_nil academy.data_sharing_consent_accepted_at
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
    assert_includes response.body, 'aria-label="Breadcrumb"'
    assert_includes response.body, "Home"
    assert_includes response.body, "Academies"
    assert_includes response.body, approved.name
    assert_not_includes response.body, pending.name
  end

  test "academy form pages render breadcrumbs" do
    owner = User.create!(name: "Academy Owner", email: "breadcrumbs-owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Breadcrumb Academy", city: "Pune", status: :approved, owner: owner)
    sign_in_as owner

    get new_academy_path

    assert_response :success
    assert_includes response.body, 'aria-label="Breadcrumb"'
    assert_includes response.body, "Add academy"
    assert_includes response.body, "Add your academy profile"
    assert_includes response.body, "Once the academy is approved, you can add athletes and manage academy profile."
    assert_includes response.body, "Academy logo"
    assert_includes response.body, "File size should be less than 5 MB and PNG/JPG is accepted."
    assert_includes response.body, "PodiumCircle terms and conditions"
    assert_includes response.body, "I consent to sharing this academy profile"
    assert_not_includes response.body, "Super admin approval required"

    get edit_academy_path(academy)

    assert_response :success
    assert_includes response.body, 'aria-label="Breadcrumb"'
    assert_includes response.body, "Breadcrumb Academy"
    assert_includes response.body, "Edit academy"
  end

  test "invalid academy submission shows inline field errors" do
    owner = User.create!(name: "Demo Parent", email: "inline-academy-errors@example.com", password: "password123", role: :parent)
    sign_in_as owner

    post academies_path, params: {
      academy: {
        name: "",
        city: "",
        email: "not-an-email",
        logo_image: identity_document_upload
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Please fix the following:"
    assert_includes response.body, "Name can&#39;t be blank"
    assert_includes response.body, "City can&#39;t be blank"
    assert_includes response.body, "Email is invalid"
    assert_includes response.body, "Logo image file size should be less than 5 MB and PNG/JPG is accepted"
    assert_operator response.body.scan("field-error-message").size, :>=, 4
    assert_operator response.body.scan("field_with_errors").size, :>=, 4
  end

  test "academy creation requires terms and data sharing consent" do
    owner = User.create!(name: "Demo Parent", email: "academy-consent@example.com", password: "password123", role: :parent)
    sign_in_as owner

    assert_no_difference("Academy.count") do
      post academies_path, params: {
        academy: {
          name: "Consent Missing Academy",
          city: "Pune"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Terms accepted must be accepted"
    assert_includes response.body, "Data sharing consent must be accepted"
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

  test "academy show links manager to athletes without listing roster inline" do
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
    assert_includes response.body, "My athletes"
    assert_includes response.body, athletes_academy_path(academy)
    assert_not_includes response.body, "Aarohi Shah"
    assert_not_includes response.body, "Red"
  end

  test "academy owner sees other academies but not their athletes" do
    owner = User.create!(name: "Academy Owner", email: "owner-privacy@example.com", password: "password123", role: :academy_owner)
    owned_academy = Academy.create!(name: "Owned Academy", city: "Pune", status: :approved, owner: owner)
    other_academy = Academy.create!(name: "Other Academy", city: "Mumbai", status: :approved)
    owner.athletes.create!(academy: owned_academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    other_user = User.create!(name: "Other Parent", email: "other-academy-parent@example.test", password: "password123", role: :parent)
    other_user.athletes.create!(academy: other_academy, first_name: "Hidden", last_name: "Athlete", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    sign_in_as owner

    get academies_path
    assert_response :success
    assert_includes response.body, "My academies"
    assert_includes response.body, "Other academies"
    assert_includes response.body, "Owned Academy"
    assert_includes response.body, "Other Academy"
    assert_includes response.body, "academy-card"
    assert_includes response.body, "academy-card-main"
    assert_includes response.body, "academy-card-logo"
    assert_includes response.body, "My athletes"
    assert_includes response.body, "Notifications"
    assert_includes response.body, athletes_academy_path(owned_academy)
    assert_includes response.body, notifications_academy_path(owned_academy)
    assert_not_includes response.body, "academy-card-menu"
    assert_not_includes response.body, "Actions for Owned Academy"
    assert_not_includes response.body, new_athlete_path(academy_id: owned_academy.id)

    get academy_path(other_academy)
    assert_response :success
    assert_not_includes response.body, "Hidden Athlete"
    assert_not_includes response.body, "registered-athlete-list"
  end

  test "academy owner sees owned academy athletes in list view with profile links" do
    owner = User.create!(name: "Academy Owner", email: "owner-list@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved, owner: owner)
    athlete = owner.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", belt: "red")
    sign_in_as owner

    get athletes_academy_path(academy)

    assert_response :success
    assert_includes response.body, 'aria-label="Breadcrumb"'
    assert_includes response.body, "Academies"
    assert_includes response.body, "My athletes"
    assert_includes response.body, "registered-athlete-list"
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, athlete_path(athlete)
    assert_includes response.body, "kebab-menu"
    assert_includes response.body, 'aria-label="Actions for Aarohi Shah"'
    assert_includes response.body, "Copy email"
    assert_includes response.body, owner.email
    assert_includes response.body, "View profile"
    assert_includes response.body, "Remove athlete"
    assert_includes response.body, "Are you sure you want to remove Aarohi Shah from Approved Academy?"
    assert_not_includes response.body, "Edit member"
    assert_not_includes response.body, ">View<"
    assert_not_includes response.body, ">Remove<"
  end

  test "academy show presents logo contact details and top action menu" do
    owner = User.create!(name: "Academy Owner", email: "academy-show-owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(
      name: "Card Dojang",
      city: "Pune",
      state: "Maharashtra",
      country: "India",
      contact_name: "Front Desk",
      phone: "9876543210",
      email: "hello@carddojang.example",
      status: :approved,
      owner: owner
    )
    academy.logo_image.attach(tournament_image_upload)
    sign_in_as owner

    get academy_path(academy)

    assert_response :success
    assert_includes response.body, "academy-show-header"
    assert_includes response.body, "academy-show-logo"
    assert_includes response.body, "Card Dojang logo"
    assert_includes response.body, "academy-show-menu"
    assert_includes response.body, "Contact details"
    assert_includes response.body, "Contact person"
    assert_includes response.body, "Front Desk"
    assert_includes response.body, "mailto:hello@carddojang.example"
    assert_includes response.body, "9876543210"
    assert_includes response.body, "All academies"
    assert_includes response.body, "Edit academy"
    assert_includes response.body, "Add athlete"
    assert_not_includes response.body, '<div class="form-actions">'
  end

  test "super admin sees edit member action in academy athlete menu" do
    super_admin = User.create!(name: "Super Admin", email: "academy-menu-admin@example.com", password: "password123", role: :super_admin)
    athlete_user = User.create!(name: "Athlete User", email: "academy-menu-athlete@example.test", password: "password123", role: :athlete)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved)
    athlete = athlete_user.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", belt: "red")
    sign_in_as super_admin

    get athletes_academy_path(academy)

    assert_response :success
    assert_includes response.body, "kebab-menu"
    assert_includes response.body, "Edit member"
    assert_includes response.body, edit_athlete_path(athlete)
  end

  test "academy owner sees athlete tournament registration statuses for owned academy" do
    owner = User.create!(name: "Academy Owner", email: "academy-status-owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "academy-status-athlete@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female", belt: "red", weight: 39.5)
    athlete.profile_photo.attach(tournament_image_upload)
    organizer = User.create!(name: "Organizer", email: "academy-status-organizer@example.test", password: "password123", role: :organizer)
    tournament = Tournament.create!(name: "Pune Open", organizer: organizer, start_date: 20.days.from_now.to_date, end_date: 21.days.from_now.to_date)
    newer_tournament = Tournament.create!(name: "Mumbai Cup", organizer: organizer, start_date: 45.days.from_now.to_date, end_date: 46.days.from_now.to_date)
    pending_category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_min: 33, weight_max: 37)
    verified_category = tournament.tournament_categories.find_or_create_by!(event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 33)
    newer_category = newer_tournament.tournament_categories.find_or_create_by!(event_type: "poomsae", gender: "female", age_min: 12, age_max: 14)
    tournament.registrations.create!(athlete: athlete, tournament_category: pending_category, registered_weight: 35, status: :pending, payment_receipt: payment_receipt_upload)
    verified_registration = tournament.registrations.create!(athlete: athlete, tournament_category: verified_category, registered_weight: 32.5, status: :approved, payment_receipt: payment_receipt_upload)
    newer_tournament.registrations.create!(athlete: athlete, tournament_category: newer_category, status: :pending, payment_receipt: payment_receipt_upload)
    verified_registration.registration_weight_checks.create!(checked_by: organizer, weight: 32.5)
    sign_in_as owner

    get athletes_academy_path(academy)

    assert_response :success
    assert_includes response.body, "Tournament status"
    assert_includes response.body, "tournament-status-table"
    assert_includes response.body, "tournament-status-avatar"
    assert_includes response.body, "Athlete"
    assert_includes response.body, "Category"
    assert_includes response.body, "Weight check"
    assert_includes response.body, "Status"
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, "Aarohi Shah photo"
    assert_no_match(/tournament-status-athlete-details">\s*<strong>Aarohi Shah<\/strong>\s*<small>/, response.body)
    assert_includes response.body, "Pune Open"
    assert_includes response.body, "Mumbai Cup"
    assert_includes response.body, "tournament-status-groups"
    assert_includes response.body, "tournament-status-group"
    assert_operator response.body.index("Mumbai Cup"), :<, response.body.index("Pune Open")
    assert_includes response.body, "Submitted"
    assert_includes response.body, "Weight verified"
    assert_includes response.body, "Attempt 1: 32.5 kg passed"
  end

  test "academy owner can approve athlete join request" do
    owner = User.create!(name: "Academy Owner", email: "membership-owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "membership-athlete@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    membership_request = academy.academy_membership_requests.create!(athlete: athlete, requested_by: athlete_user)
    sign_in_as owner

    get notifications_academy_path(academy)

    assert_response :success
    assert_includes response.body, "Notifications"
    assert_includes response.body, "added Approved Academy in their athlete profile"
    assert_not_includes response.body, "Review athletes who asked to join"
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, athlete_path(athlete, return_to: notifications_academy_path(academy))
    assert_includes response.body, approve_academy_academy_membership_request_path(academy, membership_request)
    assert_includes response.body, reject_academy_academy_membership_request_path(academy, membership_request)
    assert_includes response.body, dismiss_academy_academy_membership_request_path(academy, membership_request)

    get athlete_path(athlete, return_to: notifications_academy_path(academy))
    assert_response :success
    assert_includes response.body, "Aarohi Shah"
    assert_includes response.body, notifications_academy_path(academy)

    patch approve_academy_academy_membership_request_path(academy, membership_request)

    assert_redirected_to notifications_academy_path(academy)
    assert_equal "Athlete added to academy.", flash[:notice]
    assert_equal academy, athlete.reload.academy
    assert_predicate membership_request.reload, :approved?
    assert_equal owner, membership_request.reviewed_by
    assert_not_nil membership_request.reviewed_at
  end

  test "academy owner can dismiss join request notification without changing request status" do
    owner = User.create!(name: "Academy Owner", email: "membership-dismiss-owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "membership-dismiss-athlete@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    membership_request = academy.academy_membership_requests.create!(athlete: athlete, requested_by: athlete_user)
    sign_in_as owner

    assert_no_difference("AcademyMembershipRequest.pending.count") do
      patch dismiss_academy_academy_membership_request_path(academy, membership_request)
    end

    assert_redirected_to notifications_academy_path(academy)
    assert_equal "Notification dismissed.", flash[:notice]
    assert_predicate membership_request.reload, :pending?
    assert_not_nil membership_request.dismissed_at

    get notifications_academy_path(academy)
    assert_response :success
    assert_not_includes response.body, "Aarohi Shah"
    assert_includes response.body, "No notifications"
    assert_includes response.body, "New athlete join requests and other notifications will appear here."
    assert_not_includes response.body, "New athlete join requests will appear here."
  end

  test "academy owner can reject athlete join request" do
    owner = User.create!(name: "Academy Owner", email: "membership-reject-owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "membership-reject-athlete@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    membership_request = academy.academy_membership_requests.create!(athlete: athlete, requested_by: athlete_user)
    sign_in_as owner

    patch reject_academy_academy_membership_request_path(academy, membership_request)

    assert_redirected_to notifications_academy_path(academy)
    assert_equal "Athlete request rejected.", flash[:notice]
    assert_nil athlete.reload.academy_id
    assert_predicate membership_request.reload, :rejected?
    assert_equal owner, membership_request.reviewed_by
  end

  test "academy owner assigning athlete to own academy does not need approval" do
    owner = User.create!(name: "Academy Owner", email: "direct-add-owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved, owner: owner)
    sign_in_as owner

    assert_no_difference("AcademyMembershipRequest.count") do
      assert_difference("Athlete.count", 1) do
        assert_difference("User.athlete.count", 1) do
          assert_enqueued_emails 1 do
            post athletes_path, params: {
              athlete: {
                account_email: "academy-created-athlete@example.test",
                first_name: "Aarohi",
                last_name: "Shah",
                date_of_birth: Date.new(2014, 5, 12),
                gender: "female",
                academy_id: academy.id
              }.merge(consent_params)
            }
          end
        end
      end
    end

    athlete = Athlete.order(:created_at).last
    assert_equal academy, athlete.academy
    assert_equal "academy-created-athlete@example.test", athlete.user.email
    assert_predicate athlete.user, :athlete?
    assert_redirected_to academy_path(academy)
    assert_equal "Athlete account created and sign-in details sent.", flash[:notice]
  end

  test "academy owner cannot create athlete with email already used by another role" do
    owner = User.create!(name: "Academy Owner", email: "direct-add-duplicate-owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved, owner: owner)
    User.create!(name: "Existing Organizer", email: "used-email@example.test", password: "password123", role: :organizer)
    sign_in_as owner

    assert_no_difference(["User.count", "Athlete.count"]) do
      assert_no_enqueued_emails do
        post athletes_path, params: {
          athlete: {
            account_email: "used-email@example.test",
            first_name: "Aarohi",
            last_name: "Shah",
            date_of_birth: Date.new(2014, 5, 12),
            gender: "female",
            academy_id: academy.id
          }.merge(consent_params)
        }
      end
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Account email is already used by another account"
  end

  test "academy owner removing athlete detaches academy and notifies athlete" do
    owner = User.create!(name: "Academy Owner", email: "remove-athlete-owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved, owner: owner)
    athlete_user = User.create!(name: "Athlete User", email: "removed-athlete@example.test", password: "password123", role: :athlete)
    athlete = athlete_user.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    membership_request = academy.academy_membership_requests.create!(athlete: athlete, requested_by: athlete_user, status: :approved, reviewed_by: owner, reviewed_at: Time.current)
    sign_in_as owner

    assert_no_difference("Athlete.count") do
      assert_enqueued_emails 1 do
        delete athlete_path(athlete)
      end
    end

    assert_redirected_to academy_path(academy)
    assert_equal "Athlete removed from academy.", flash[:notice]
    assert_nil athlete.reload.academy_id
    assert_nil athlete.external_academy_name
    assert_predicate membership_request.reload, :rejected?
  end

  test "academy owner remove unlinks even when athlete account belongs to owner" do
    owner = User.create!(name: "Academy Owner", email: "remove-own-athlete-owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Owner Athlete Academy", city: "Pune", status: :approved, owner: owner)
    athlete = owner.athletes.create!(academy: academy, first_name: "Aarohi", last_name: "Shah", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    sign_in_as owner

    assert_no_difference("Athlete.count") do
      assert_enqueued_emails 1 do
        delete athlete_path(athlete)
      end
    end

    assert_redirected_to academy_path(academy)
    assert_nil athlete.reload.academy_id
    assert Athlete.exists?(athlete.id)
  end

  test "academy index cards hide visible status label and open from card body" do
    academy = Academy.create!(name: "Card Dojang", city: "Pune", status: :approved)
    academy.logo_image.attach(tournament_image_upload)

    get academies_path

    assert_response :success
    assert_includes response.body, "academy-card"
    assert_includes response.body, "academy-card-logo"
    assert_includes response.body, "academy-card-body"
    assert_includes response.body, "Open Card Dojang"
    assert_includes response.body, academy_path(academy)
    assert_includes response.body, "Card Dojang logo"
    assert_not_includes response.body, "status-pill status-approved"
  end

  test "index searches academies and orders oldest first" do
    newer = Academy.create!(name: "Newer Academy", city: "Pune", state: "Maharashtra", status: :approved)
    older = Academy.create!(name: "Older Academy", city: "Pune", state: "Maharashtra", status: :approved)
    hidden = Academy.create!(name: "Hidden Academy", city: "Delhi", state: "Delhi", status: :approved)
    older.update_column(:created_at, 2.days.ago)
    newer.update_column(:created_at, 1.day.ago)

    get academies_path(q: "pune")

    assert_response :success
    assert_operator response.body.index(older.name), :<, response.body.index(newer.name)
    assert_not_includes response.body, hidden.name
    assert_includes response.body, "Search academies"
  end

  test "academy show sorts athletes by name" do
    owner = User.create!(name: "Academy Owner", email: "sort-owner@example.com", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Approved Academy", city: "Pune", status: :approved, owner: owner)
    owner.athletes.create!(academy: academy, first_name: "Zoya", last_name: "Kapoor", date_of_birth: Date.new(2014, 5, 12), gender: "female")
    owner.athletes.create!(academy: academy, first_name: "Aarav", last_name: "Mehta", date_of_birth: Date.new(2014, 5, 12), gender: "male")
    sign_in_as owner

    get athletes_academy_path(academy)

    assert_response :success
    assert_operator response.body.index("Aarav Mehta"), :<, response.body.index("Zoya Kapoor")
  end

  test "index paginates academies" do
    13.times { |index| Academy.create!(name: "Academy #{index}", city: "Pune", status: :approved) }

    get academies_path

    assert_response :success
    assert_includes response.body, "Page 1 of 2"
  end

  test "super admin can delete academy" do
    super_admin = User.create!(name: "Super Admin", email: "delete-academy-admin@example.test", password: "password123", role: :super_admin)
    academy = Academy.create!(name: "Delete Academy", city: "Pune", status: :approved)
    sign_in_as super_admin

    get academies_path
    assert_response :success
    assert_includes response.body, "Delete"

    get academy_path(academy)
    assert_response :success
    assert_includes response.body, "Delete academy"

    assert_difference("Academy.count", -1) do
      delete academy_path(academy)
    end

    assert_redirected_to academies_path
    assert_equal "Academy removed.", flash[:notice]
    assert_not Academy.exists?(academy.id)
  end

  test "academy owner cannot delete academy" do
    owner = User.create!(name: "Academy Owner", email: "no-delete-academy-owner@example.test", password: "password123", role: :academy_owner)
    academy = Academy.create!(name: "Protected Academy", city: "Pune", status: :approved, owner: owner)
    sign_in_as owner

    get academy_path(academy)
    assert_response :success
    assert_not_includes response.body, "Delete academy"

    assert_no_difference("Academy.count") do
      delete academy_path(academy)
    end

    assert_response :not_found
    assert Academy.exists?(academy.id)
  end
end
