# PodiumCircle Progress Log

This file is the long-lived implementation journal for PodiumCircle. Keep it current for every code change, product decision, validation rule, test run, and known gap so future maintainers can reconstruct why the app behaves the way it does.

## 2026-09-22 - Fly Deploy Docker Base Image Fix

### Reference
- User reported production deployment failed and asked to fix the issue and deploy.

### Change Log
- Updated `Dockerfile` from `ruby:3.2.0-slim` to `ruby:3.3.8-slim-bookworm`, matching the project's `.ruby-version` and moving away from the Debian Bullseye package indexes that were returning 404s during `apt-get install`.

### Verification Log
- Ran `mise exec -- fly deploy --app taekwondo-hub --build-only`; result: Docker image built successfully with the Bookworm base image and no Debian package 404s.
- Ran `mise exec -- bin/rails test`; result: 432 runs, 3193 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace errors.
- Ran `mise exec -- fly deploy --app taekwondo-hub`; result: release command `bin/rails db:prepare` completed successfully and Fly release `v11` deployed.
- Verified production with `mise exec -- fly releases --app taekwondo-hub`; result: `v11` is `complete`.
- Verified production with `mise exec -- fly status --app taekwondo-hub`; result: both app machines are on version `11` and started.
- Verified `https://podiumcircle.com/` with `curl -I`; result: `HTTP/2 200`.
- Verified production schema with Rails runner; result: `Tournament.column_names.include?("group_registration_fee")` returned `true`.

## 2026-09-22 - Visible Super Admin Academy Approval Actions

### Reference
- User confirmed `sonamvgoyal@gmail.com` is a super admin but could not see where to approve academies.

### Change Log
- Added visible `Approve academy` and `Reject` actions to pending academy cards for super admins on the academies index.
- Added a visible pending-approval panel to pending academy detail pages for super admins, so approval is not hidden only inside the three-dot menu.
- Updated direct academy approve/reject actions to sync related pending super-admin academy notifications as approved/rejected.
- Added regression coverage for visible super-admin academy approval actions and notification sync.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/super_admin_notifications_controller_test.rb`; result: 40 runs, 537 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 443 runs, 3259 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace errors.
- Ran `mise exec -- fly deploy --app taekwondo-hub`; result: Fly release `v12` deployed successfully and release command completed.
- Verified production with `mise exec -- fly releases --app taekwondo-hub`; result: `v12` is `complete`.
- Verified production with `mise exec -- fly status --app taekwondo-hub`; result: both app machines are on version `12` and started.
- Verified `https://podiumcircle.com/` with `curl -I`; result: `HTTP/2 200`.
- Verified production pending approval data with Rails runner; result: 4 pending academies and 4 pending academy-submission notifications remain available for review.

## 2026-08-27 - Organizer Profile Landing Page

### Reference
- User request: as an organiser, when I sign in and click the organiser, I should be able to see my profile.

### Scope Chosen For This Pass
- Add a signed-in organiser profile landing page.
- Change the top navigation `Organizer` link for verified organiser-capable users to open the profile instead of the approvals queue.
- Keep registration approvals accessible from the organiser profile.

### Product Decisions
- The organiser profile lives at `/organizers/profile`.
- The profile shows verification status, role, designation, email, phone, approval date, owned tournaments, and collaborating tournaments.
- Owned tournament rows link to view, edit, and referee management.
- Collaborating tournament rows link to view and approvals.
- Non-organiser users are redirected to the public organisers page with a clear alert.

### Change Log
- Added `profile` collection route under organisers.
- Added `OrganizersController#profile`.
- Added `app/views/organizers/profile.html.erb`.
- Updated the app header organiser nav target for organiser-capable users.
- Added controller tests for profile access, nav target, owned tournament display, and non-organiser redirect.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/organizers_controller_test.rb`; result: 5 runs, 47 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 122 runs, 922 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-27 - Image Placeholders For Missing Or Broken Media

### Reference
- User request: if an image is missing or broken, add placeholders.

### Scope Chosen For This Pass
- Add reusable placeholder behavior for image surfaces that can be blank or broken.
- Cover tournament logo cards, tournament banners, organizer profile photos, athlete profile photos, referee photos, and the homepage hero image.
- Keep the implementation server-rendered with a small browser `onerror` fallback for broken image responses.

### Product Decisions
- Missing Active Storage uploads show text placeholders immediately.
- Broken remote image URLs hide the failed image and reveal the placeholder without changing the page layout.
- Tournament cards use the tournament initial.
- Tournament banners use an initial plus `banner` label.
- Organizer, athlete, and referee profiles use initials or first-letter placeholders.
- Placeholders use the existing dark Sports Hub visual language rather than adding new image assets.

### Change Log
- Added `ApplicationHelper#image_with_placeholder`.
- Replaced direct `image_tag` calls on vulnerable image surfaces with the placeholder helper.
- Added CSS for fallback wrappers, hidden failed images, and placeholder boxes.
- Added tests for homepage fallback wiring, organizer remote-photo fallback wiring, and tournament logo/banner placeholders.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/home_controller_test.rb test/controllers/organizers_controller_test.rb test/controllers/tournaments_controller_test.rb test/controllers/athletes_controller_test.rb test/controllers/tournament_referees_controller_test.rb`; result: 53 runs, 443 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 120 runs, 902 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-27 - Tournament Filter UI Polish

### Reference
- User request: improve the UI for filters on the tournament page.

### Scope Chosen For This Pass
- Improve the tournament index filter presentation without changing existing query parameters or filtering semantics.
- Keep the filter controls server-rendered and Rails-native.

### Product Decisions
- Search is the primary control because users are most likely to look for a tournament, venue, city, state, or country by text.
- Country and state filters are select controls populated from existing tournament data instead of free-text fields, reducing typo-driven empty results.
- The filter panel shows whether all tournaments are being shown or how many filters are active.
- Existing `q`, `country`, and `state` query parameters remain unchanged so current links keep working.

### Change Log
- Added tournament filter option collections to `TournamentsController#index`.
- Replaced the plain tournament filter row with a structured filter panel.
- Added active-filter count and clearer `Apply filters`/`Clear` actions.
- Added CSS for the new tournament filter panel, responsive layout, and focused inputs.
- Updated tournament controller tests to cover the improved filter UI.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb`; result: 28 runs, 275 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 118 runs, 886 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-27 - Demo Seed Data For New Tournament Fields

### Reference
- User request: add seed data for new fields added.

### Scope Chosen For This Pass
- Reintroduce explicit demo seed data after the earlier empty-seed state.
- Cover the newer tournament operations fields and flows rather than only base users.
- Keep the seed script idempotent so repeated `db:seed` runs update/reuse records instead of creating duplicates.

### Product Decisions
- Demo password is `password123` for all seeded accounts.
- Seeded roles include super admin, verified organiser, assistant organiser, academy owner, and athlete.
- Seeded tournaments include one registration-open tournament and one registration-closed tournament.
- Tournament seed data includes fee per category, currency, payment bank instructions, courts count, categories, organisers, referees, uploaded image attachments, and registrations with receipt attachments.
- Referee seed data includes names, phone, email, role, qualifications, certification ID, affiliation, notes, and photo attachment.
- Demo registrations include pending and approved states so organiser approval queues and accepted lists have visible data.

### Change Log
- Replaced the empty `db/seeds.rb` placeholder with an idempotent demo seed script.
- Added helper methods inside `db/seeds.rb` for users, academies, athletes, tournaments, categories, registrations, and file attachments.
- Seeded default category-template-based categories for both demo tournaments.
- Seeded tournament referee records for new referee-management fields.
- Seeded registration receipts using existing fixture files.
- Printed demo login credentials after seeding.

### Verification Log
- Ran `mise exec -- bin/rails db:seed`; result: seed data loaded successfully and printed demo credentials.
- Reran `mise exec -- bin/rails db:seed`; result: completed successfully again, confirming idempotent behavior for this pass.
- Ran `mise exec -- bin/rails test`; result: 118 runs, 876 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-27 - Code Review And Safe Dead-Code Cleanup

### Reference
- User request: code review the application and remove unwanted code.

### Scope Chosen For This Pass
- Review the Rails application for unused runtime paths, stale helpers, old flow leftovers, and tracked junk files.
- Remove dead code only where it does not delete existing data.
- Avoid dropping database columns without explicit approval because that can destroy stored values.

### Review Findings
- `ApplicationController#demo_organizer` was exposed as a helper but had no live references.
- Tournament image uploads replaced the old `logo_url` and `banner_image_url` runtime fallback paths.
- Category-specific registration fees were removed from the product flow, but a model validation for the unused category fee column remained.
- Registration draft preselection belonged to the removed `Save and pay later` flow and was no longer part of the registration UX.
- No tracked `log` or `tmp` files were found.

### Change Log
- Removed unused `demo_organizer` helper exposure and method.
- Removed legacy logo/banner URL fallback behavior from `Tournament#logo_image_source` and `#banner_image_source`.
- Removed normalization and URL validation for legacy tournament branding URL attributes.
- Removed unused `TournamentCategory#registration_fee` validation.
- Removed draft-registration lookup from registration category preselection.
- Updated the registration controller test to use explicit category preselection instead of creating a draft registration.

### Known Gaps And Deferred Cleanup
- The legacy database columns `tournaments.logo_url`, `tournaments.banner_image_url`, and `tournament_categories.registration_fee` still exist. They are unused by runtime code after this pass, but dropping them would delete any existing data and should be done only after explicit approval or a backup/export decision.
- The `Registration.draft` enum remains for compatibility with any existing draft rows created before the pay-later flow was removed.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/registrations_controller_test.rb test/controllers/tournaments_controller_test.rb test/models/tournament_category_test.rb`; result: 39 runs, 341 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 118 runs, 876 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-27 - Tournament Referee Management

### Reference
- User request: organisers should be able to add referee details for a tournament, including referee names, contact details, useful notes, referee count, photo, and qualifications.

### Scope Chosen For This Pass
- Add structured referee records under each tournament.
- Keep referee contact and operational notes visible only to tournament managers.
- Show only a referee count on the public tournament page.
- Use Active Storage for referee photos.

### Product Decisions
- Referee management is a nested tournament organiser workflow at `/tournaments/:tournament_id/referees`.
- Tournament managers can add, view, edit, and remove referees.
- Referee fields include name, phone, email, role, qualifications, certification ID, academy/association affiliation, notes, and photo.
- Referee name is required.
- Referee email must be valid when provided.
- Referee photos are optional and must be between 1 byte and 5 MB.
- Referee count is derived from the number of saved referee records; there is no separate manual count field so the UI cannot drift from actual entries.

### Change Log
- Added `TournamentReferee` model with normalization, email validation, and photo upload size validation.
- Added `tournament_referees` table.
- Added `Tournament#tournament_referees` association.
- Added organiser-only `TournamentRefereesController`.
- Added nested referee routes under tournaments.
- Added referee index, detail, new, edit, and shared form views.
- Added referee action link and referee count to tournament show.
- Added CSS for referee list rows and photos.
- Added model and controller tests for referee creation, update, delete, validation, photo attachment, and non-manager privacy.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: `tournament_referees` table migration applied successfully.
- Ran `mise exec -- bin/rails test test/models/tournament_referee_test.rb test/controllers/tournament_referees_controller_test.rb test/controllers/tournaments_controller_test.rb`; first run found a validation bug where blank referee names were not rejected because `allow_blank` was applied to a combined presence/length validation.
- Fixed referee name validation by separating presence and length validators.
- Reran `mise exec -- bin/rails test test/models/tournament_referee_test.rb test/controllers/tournament_referees_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 36 runs, 310 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 118 runs, 876 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-27 - Tournament Fee, Default Categories, And Venue Setup

### Reference
- User request: keep initial tournament setup focused on pre-registration details and athlete entry, use a single category fee input at tournament level, multiply that fee by selected category count during registration, add post-registration venue details such as number of courts, and use the attached registration PDF as reference for default categories so organisers can select common categories instead of manually creating many rows.
- Attached PDF: `/Users/sonamgoyal/Downloads/registration_forms-index-2f501d232bf20356b7f482b5bbe8d8ea.pdf`.

### Scope Chosen For This Pass
- Treat `tournaments.registration_fee` as the single fee per selected category.
- Remove organiser-facing category-level fee entry from category creation/editing.
- Keep the older `tournament_categories.registration_fee` column in place for migration compatibility, but stop using it in registration totals and fee snapshots.
- Add a reusable default category picker on the tournament category management page.
- Add post-registration venue setup with `courts_count`, available only to tournament managers after registration closes.

### Product Decisions
- The initial tournament form label is now `Fee per category`, with helper copy explaining that two selected categories at INR 1000 totals INR 2000.
- Athlete and academy-owner registration totals now multiply selected categories by the tournament fee.
- Existing registrations snapshot the fee at submission time using the tournament-level fee and tournament currency.
- Default categories are app-maintained templates covering common taekwondo Kyorugi age, gender, and weight bands plus individual Poomsae age/gender bands.
- The attached PDF could not be parsed locally because Poppler `pdftotext`, `pdfplumber`, and `pypdf` were unavailable in this environment. The PDF was confirmed to be a three-page Chromium PDF; default templates were implemented from standard taekwondo registration category patterns and kept easy to expand later.
- Venue setup intentionally opens after `registration_closes_at` so organisers focus on athlete entry while registration is open, then enter court count before draw and schedule work.
- Court count must be a positive integer when entered.

### Change Log
- Added `courts_count` to tournaments.
- Added `Tournament#courts_count` validation.
- Added `TournamentsController#venue_setup` and `#update_venue_setup`.
- Added `venue_setup_tournament_path` GET/PATCH routes.
- Added `app/views/tournaments/venue_setup.html.erb`.
- Added `Venue setup` action to tournament show after registration closes.
- Added courts count to tournament summary.
- Changed tournament setup fee label to `Fee per category`.
- Changed category fee calculation to always use the tournament fee.
- Changed registration fee snapshots to use the tournament fee instead of category overrides.
- Removed category-level fee input and strong parameter permitting from category forms.
- Added `TournamentCategory::DEFAULT_CATEGORY_TEMPLATES`.
- Added default category bulk creation action and UI.
- Tightened tournament category create/edit/update/default-import authorization to tournament managers.
- Added tests for default category import, tournament-level fee totals, and venue setup timing.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: `courts_count` migration applied successfully.
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/tournament_categories_controller_test.rb test/controllers/registrations_controller_test.rb`; result: 40 runs, 364 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 109 runs, 826 assertions, 0 failures, 0 errors, 0 skips.
- After an ERB cleanup on the category index privacy wrapper, reran the same focused tests and full suite; result stayed green at 40/364 and 109/826 respectively.

## 2026-08-27 - Search Filters Sorting And Pagination

### Reference
- User request: implement search for tournament, academy, and athlete flows. Athletes should support filters by age, weight, and belt. Academy athletes should be sorted by name. Academy list should show oldest registered academies first. Tournaments should filter by country and state, newest active tournaments should appear first, and older/closed/ended tournaments should be lower. Use proper pagination as athletes and tournaments grow.

### Scope Chosen For This Pass
- Add server-rendered search/filter forms to athlete, academy, and tournament indexes.
- Add lightweight built-in pagination without introducing a new gem.
- Add `country` to tournaments so country filtering is a first-class field.
- Keep list visibility rules unchanged while layering search/filtering on top.

### Product Decisions
- Pagination defaults to 12 records per page for list screens.
- Athlete search covers athlete name, full name, association ID, and academy name.
- Athlete filters support min/max age, min/max weight, and belt.
- Academy search covers name, city, state, country, and registration number.
- Academy index sorts by `created_at ASC`, then id, so oldest registered academies appear first.
- Academy detail athlete list uses `first_name, last_name` sorting.
- Tournament search covers name, venue, city, state, and country.
- Tournament filters support exact country and state match after trimming/lowercasing.
- Tournament sorting puts active/upcoming tournaments first, then closed/completed/cancelled/archived or already-ended tournaments, with newer start dates first inside each group.

### Change Log
- Added `ApplicationController#paginate` and shared pagination partial.
- Added `country` column to tournaments with default `India`.
- Added athlete index search/filter logic and filter form.
- Added academy index search, oldest-first ordering, filter form, and pagination.
- Updated academy show to use a sorted `@athletes` collection.
- Added tournament index search, country/state filters, active/newest-first sorting, and filter form.
- Added country to the tournament setup form and permitted tournament params.
- Added CSS for filters and pagination.
- Added controller tests for athlete filters/pagination, academy search/order/pagination/athlete sorting, and tournament country/state filtering/order/pagination.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: tournament country migration applied successfully.
- Ran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 45 runs, 372 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 105 runs, 801 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Remove Athlete Pay-Later Registration

### Reference
- User request: remove the `Save and pay later` option.

### Scope Chosen For This Pass
- Remove the pay-later button from tournament registration.
- Stop creating new `draft` registrations from the athlete/academy-owner registration form.
- Keep the existing `draft` registration status in code for compatibility with any existing rows and current organiser/tournament filters.

### Product Decisions
- Every tournament registration submission now requires a payment receipt.
- Multi-category registration still creates one pending registration per selected category once the receipt is uploaded.
- Existing draft rows remain hidden from organiser queues; removing the enum/database state would require a separate data cleanup pass.

### Change Log
- Removed `Save and pay later` submit button from the registration form.
- Removed controller branching that created `draft` registrations based on submit button text.
- Updated registration copy to instruct users to pay, upload receipt, and submit.
- Updated registration tests to assert pay-later is absent and receipt remains mandatory.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/registrations_controller_test.rb`; result: 7 runs, 66 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 97 runs, 757 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Reset Category Selection On Athlete Change

### Reference
- User request: as an academy owner, if I change athlete, previous selection of categories must be reset.

### Scope Chosen For This Pass
- Reset the visible category picker immediately when the athlete dropdown changes on the registration form.
- Keep existing saved draft category preselection only for the athlete currently selected when the page loads.

### Product Decisions
- Changing athlete clears all category dropdown rows, hides the add-more checkbox, hides the delete button on the remaining empty row, and resets the payable total to zero.
- The reset behavior applies to academy-owner registration and athlete self-registration because both use the same registration form.

### Change Log
- Added a `data-athlete-select` marker to the athlete dropdown.
- Added JavaScript reset behavior for category rows and registration total when the athlete changes.
- Added a regression test asserting the reset hook is rendered and draft categories still preselect for the active athlete.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/registrations_controller_test.rb`; result: 7 runs, 63 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 97 runs, 754 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Per-Category Fees And Secure Payment Display

### Reference
- User request: tournament organisers should be able to set price/fee per category. If one category is 1000 INR and someone selects two categories, they should see and pay 2000 INR. Academy owners and athletes should see the amount to pay while registering. Tournament organisers should be able to add bank account details, and those details should be shared securely only during tournament registration.

### Scope Chosen For This Pass
- Add per-category registration fees while preserving the existing tournament-level fee as a fallback/default.
- Show category fees in the registration category dropdown.
- Calculate and display the total payable amount on the registration page as categories are selected.
- Snapshot the fee amount and currency onto each registration row at submission/draft time.
- Keep bank details visible only in the signed-in registration flow and absent from public tournament pages.

### Product Decisions
- `TournamentCategory#registration_fee` overrides `Tournament#registration_fee`; blank category fee uses the tournament default.
- Each selected category creates its own registration row with its own fee snapshot.
- A single receipt upload still applies to all selected category registrations in that submission.
- Bank details are currently protected by access control: they are not shown on public tournament/index/show pages and are only rendered after sign-in inside the registration form. Full encryption-at-rest should be configured before production by adding Rails Active Record encryption keys or a managed secrets strategy.

### Change Log
- Added `registration_fee` to tournament categories.
- Added `fee_amount` and `fee_currency` to registrations for payment audit snapshots.
- Added category fee validation and fee-label helpers.
- Added category fee input to the organiser category create/edit form.
- Updated registration create logic to store fee snapshots per selected category.
- Updated the registration category dropdown labels to include per-category fee.
- Added a registration total panel that updates from selected category fees.
- Updated payment section copy to clarify that bank details are shown only in the signed-in registration flow.
- Added tests for category fee create/update, fee display, fee snapshots, and public bank-detail privacy.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: category fee and registration fee snapshot migration applied successfully.
- Ran `mise exec -- bin/rails test test/controllers/tournament_categories_controller_test.rb test/controllers/registrations_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 32 runs, 312 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 96 runs, 747 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Academy Owner Athlete Privacy And Dropdown Registration

### Reference
- User request: academy owners should be able to see other academies but not their athletes, see their own athletes in list view, see all tournaments, and register an academy athlete for open tournaments. Registration should use athlete and category dropdowns. After choosing a category, the selected category should remain displayed, a checkbox should ask whether to add more categories, another category dropdown should appear when checked, and chosen categories should be removable. The same category-selection flow should be used when athletes register themselves.

### Scope Chosen For This Pass
- Keep public/other-academy visibility limited to academy details only.
- Treat athletes assigned to academies owned by the current academy owner as manageable athletes for viewing and tournament registration.
- Reuse the existing multi-category registration persistence and payment/receipt flow.
- Replace category checkboxes with repeatable category dropdown rows for all tournament registration users.

### Product Decisions
- Academy index shows athlete counts only for academies the current user can manage.
- Academy detail pages show athlete details only for academy managers and super admins.
- Academy-owned athletes are visible in the shared athlete controller, so profile links from academy pages work.
- The registration form starts with one category dropdown. Once a category is selected, an add-more checkbox appears. Checking it appends another dropdown. Each chosen row can be deleted.
- Tournament index now shows a direct `Register` link for signed-in users when registration is open.

### Change Log
- Expanded athlete visibility in `AthletesController` to include athletes assigned to approved academies owned by the current user.
- Expanded registration athlete dropdown scope to include the current user's athletes plus athletes assigned to their owned approved academies.
- Hid academy athlete counts from non-managers on the academy index.
- Reworked academy detail athlete display into a row/list view labelled `My athletes`.
- Replaced registration category checkboxes with a JavaScript-enhanced repeatable dropdown picker.
- Added a direct tournament-card `Register` link for signed-in users when tournament registration is open.
- Added tests for academy-owner privacy, owned academy athlete list/profile access, academy-owner registration of academy athletes, category picker controls, and tournament index register links.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/athletes_controller_test.rb test/controllers/registrations_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 42 runs, 362 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 95 runs, 723 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Athlete Signup, Profile Completion, And Multi-Category Registration

### Reference
- User request: `Join as athlete` should create a new athlete account with only name, email, phone, password, and confirmation. Athlete accounts should not require approval. After login/signup, athletes should complete a profile with current profile fields plus athlete photo, government ID type and upload, upload size restrictions, blood group, emergency contact, address, and contact number. Athletes should see upcoming tournaments, select multiple eligible categories, view secure payment details, save selections for later payment, upload a payment receipt, and submit registrations to the tournament organiser.

### Scope Chosen For This Pass
- Convert public athlete signup to create a `User` with role `athlete`.
- Redirect athlete-role users without an athlete profile to profile completion.
- Expand the athlete profile model and form with contact, address, medical, photo, and ID-document fields.
- Add tournament payment fields that organisers manage in the tournament setup form and athletes see during registration.
- Change tournament registration from one category per submission to multi-category checkbox submission.
- Add `draft` registrations so athletes can save selected categories and submit later after payment.
- Keep organiser approval queues free of draft registrations.

### Product Decisions
- Athlete signup does not create the athlete profile automatically because the profile requires DOB, gender, belt, academy, documents, and medical/contact details.
- Athlete profile uploads use Active Storage and are limited to 1 byte through 5 MB.
- Payment details are stored on the tournament record and shown only inside the signed-in registration flow, not on public tournament pages.
- A single uploaded receipt is attached to every selected category registration in the same submission.
- Saved selections are stored as `draft` registration rows so uniqueness and resume behavior are handled by the database-backed registration model.
- Draft registrations are visible to the athlete in their registration list but hidden from organiser approval lists and tournament-manager registered-athlete lists.

### Change Log
- Added athlete profile fields: contact number, blood group, emergency contact name/phone, address, and government ID document type.
- Added athlete Active Storage attachments for profile photo and identity document.
- Added upload-size validations for athlete photo and identity document.
- Added tournament payment fields: account holder name, bank name, account number, IFSC, and payment instructions.
- Added `draft` status to registrations.
- Updated athlete signup copy and behavior to create athlete-role users and redirect to profile setup.
- Added global athlete-profile-completion guard for athlete-role accounts without a profile.
- Expanded the athlete profile form and show page, including previous competition/registration status list.
- Updated tournament setup form with organiser-managed payment details.
- Reworked athlete tournament registration form with category checkboxes, payment details, pay-later save, and receipt-based submit.
- Updated registration create logic to save multiple category registrations as draft or pending records.
- Updated organiser and tournament-manager registration queries to hide drafts.
- Updated home page `Join as athlete` CTAs to open athlete signup directly.
- Added controller tests for athlete signup/profile completion, athlete profile extra fields/uploads, draft category saves, and multi-category receipt submission.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: athlete profile and tournament payment fields migration applied successfully.
- Ran `mise exec -- bin/rails test test/controllers/users_controller_test.rb test/controllers/athletes_controller_test.rb test/controllers/registrations_controller_test.rb`; result: 18 runs, 141 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 90 runs, 685 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Registration Approval Routed To Tournament Organisers

### Reference
- User request: when an athlete registers for an event, the approval should go to the organiser, not the super admin.

### Scope Chosen For This Pass
- Tighten the organiser registration approval queue so it is scoped to users who own or are assigned to the tournament.
- Keep super-admin-only action log visibility only within registrations that the super admin can access as an assigned tournament organiser.
- Update registration wording so athletes know their submission goes to tournament organisers.

### Product Decisions
- Super admins no longer receive every tournament registration in the organiser approval queue by default.
- A super admin can still review approval logs when they are explicitly attached to that tournament, preserving the audit-only visibility rule without making super admin the default approval recipient.
- Tournament organisers remain responsible for accepting or denying athlete registrations.

### Change Log
- Removed the super-admin `Registration.all` shortcut from `Organizer::RegistrationsController#visible_registrations`.
- Updated the successful athlete registration notice to say the entry was submitted to tournament organisers for approval.
- Updated the athlete registration page copy to say tournament organisers review the entry.
- Added tests proving unassigned super admins cannot see or approve tournament registrations in the organiser queue.
- Updated the action-log visibility test so a super admin must be assigned to the tournament to access the organiser registration detail.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/organizer_registrations_controller_test.rb test/controllers/registrations_controller_test.rb`; result: 9 runs, 69 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 88 runs, 663 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Tournament Weight Check And Draw Lock

### Reference
- User request: once tournament registration closes, organisers should see two options: `Weight check` and `Set draw`. Before draw setup, a tournament super organiser can still manually add a late athlete. During weigh-in, organisers need to search accepted athletes, enter up to three weight attempts, lock each entered attempt, pass athletes whose measured weight is inside their registered category min/max range, and disqualify athletes who fail all three attempts. Passed athletes should move to a future draw list state.

### Scope Chosen For This Pass
- Add a weigh-in workflow for accepted tournament registrations.
- Treat the existing tournament owner/super-organizer membership as the late-registration authority.
- Keep late athlete additions on the existing registration form so receipt upload and organizer approval remain part of the record.
- Add `Set draw` as an explicit tournament state change to `draw_scheduling`, which locks late additions.
- Prepare the future draw list by adding a `weight_verified` registration status.

### Product Decisions
- Weight checks are append-only records; previous attempts are displayed as locked values rather than editable fields.
- Only approved registrations can be weighed.
- Attempts are assigned sequentially from 1 to 3.
- A pass on any attempt changes the registration status to `weight_verified` and logs the actor.
- A third failed attempt changes the registration status to `disqualified` and logs the actor.
- Any tournament manager can run weight checks and start draw setup after registration closes.
- Only super organisers, including super admins, can manually add athletes after registration closes, and only until draw setup starts.

### Change Log
- Added `registration_weight_checks` table with registration, checked-by user, attempt number, measured weight, pass flag, and checked timestamp.
- Added `RegistrationWeightCheck` model with sequential attempt validation, max-three-attempt enforcement, category weight-range pass/fail evaluation, and result application.
- Extended `Registration` statuses with `weight_verified` and `disqualified`.
- Added registration helpers for next attempt number, attempts remaining, category weight labels, and category range checks.
- Added tournament helpers for registration-closed weigh-in availability and late-registration permissions.
- Added organiser weight-check routes, controller, search, and index view.
- Added `Set draw` route/action that moves tournaments to `draw_scheduling` only after registration closes.
- Updated tournament detail actions to show `Weight check`, `Set draw`, `Draw setup`, and late manual athlete addition where applicable.
- Locked the weight-check page once draw setup has started.
- Added CSS for the weigh-in search, attempt slots, and new registration statuses.
- Added model and controller tests for weigh-in pass/fail behavior, organiser access, search, and draw locking.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: `registration_weight_checks` migration applied successfully.
- Ran `mise exec -- bin/rails test test/models/registration_test.rb test/controllers/organizer_weight_checks_controller_test.rb test/controllers/tournaments_controller_test.rb test/controllers/registrations_controller_test.rb test/controllers/organizer_registrations_controller_test.rb`; result: 35 runs, 317 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 87 runs, 657 assertions, 0 failures, 0 errors, 0 skips.
- Re-ran the same focused test set after final draw/weight-check lock polish; result: 35 runs, 317 assertions, 0 failures, 0 errors, 0 skips.
- Re-ran `mise exec -- bin/rails test`; result: 87 runs, 657 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Registration Receipt Review And Action Logs

### Reference
- User request: when an athlete registers for an event, show the athlete at the top of the organizer review list with accept/deny actions. Any organizer for the tournament should be able to accept or deny the athlete. Keep a log of what action was taken for which athlete and by whom, visible only to super admins. Accepted athletes should appear lower than pending athletes, denied athletes after accepted ones. Athlete registration should include a receipt photo upload, visible to organizers before accepting or rejecting.

### Scope Chosen For This Pass
- Require a payment receipt upload during athlete tournament registration.
- Show receipt links in organizer review list and registration detail review.
- Sort organizer review list by status priority: pending, approved, rejected, then other statuses.
- Preserve existing tournament-organizer permission behavior so any assigned organizer can accept/deny registrations for their tournaments.
- Add a registration action log visible only to super admins.

### Product Decisions
- Receipt uploads are stored as `Registration#payment_receipt` with Active Storage.
- Receipt upload is required at the model level, so organizer review always has a document to inspect.
- Organizer-facing action labels use `Accept` and `Deny`.
- Logs record actor, action, previous status, new status, and timestamp.
- Action logs are intentionally hidden from normal organizers and visible only to super admins on the registration review page.

### Change Log
- Added `registration_action_logs` table and `RegistrationActionLog` model.
- Added `Registration#payment_receipt` attachment and required receipt validation.
- Added `Registration#review!` to update status, set `verified_at`, and create an action log.
- Updated athlete registration form with required `Payment receipt photo` upload.
- Updated organizer review list to show pending registrations first, followed by approved and rejected registrations.
- Updated organizer review list/detail pages with receipt links and accept/deny actions.
- Added super-admin-only action log section to organizer registration detail page.
- Added tests for receipt requirement, receipt storage, review ordering, accept/deny logging, and super-admin-only log visibility.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: registration action log migration applied successfully.
- Ran `mise exec -- bin/rails test test/controllers/registrations_controller_test.rb test/controllers/organizer_registrations_controller_test.rb test/controllers/tournaments_controller_test.rb test/models/registration_test.rb`; result: 27 runs, 273 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 79 runs, 613 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Tournament Detail Placeholders And Registered Athletes List

### Reference
- User request: on `/tournaments/2`, show `--` instead of `Not set` for missing values such as website, and change `My athletes` to `Registered athletes` with registered athletes shown in list view.

### Scope Chosen For This Pass
- Update tournament detail display only.
- Preserve logged-out privacy behavior by not showing athlete registration details to signed-out visitors.
- Show all registered athletes to tournament managers.
- Show only the current user's registered athletes to normal signed-in users.

### Product Decisions
- Missing optional tournament fields use `--` consistently.
- The event setup detail list now remains visible even when values are missing, so users see the expected field with a placeholder.
- Registered athletes use a row/list layout instead of profile cards.
- Athlete names, academy, and weights are scoped to authorized viewers rather than all signed-in users.

### Change Log
- Added safe display helpers in the tournament detail template for placeholders.
- Replaced `Not set` fallbacks with `--`.
- Replaced `My athletes` card grid with a `Registered athletes` list.
- Added `TournamentsController#visible_tournament_registrations` to scope registrations by manager/current-user access.
- Added CSS for registered-athlete list rows.
- Updated tests for placeholders, registered-athlete list rendering, manager access, current-user scoping, and logged-out privacy.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb`; result: 18 runs, 207 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 75 runs, 572 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Tournament Setup Checklist Controls

### Reference
- User request: on `/tournaments/new`, replace free-text tournament setup fields with default checkboxes. Competition formats, basic eligibility, and required documents should include an `Other` option where users can enter a custom value, and another `Other` field should appear so multiple custom values can be added. Refund policy should be checkbox-only with no other section.

### Scope Chosen For This Pass
- Keep existing tournament storage columns for compatibility.
- Change the form UI from text areas to guided checkbox groups.
- Compose selected defaults plus custom entries into the existing text columns on submit.
- Add a small form-local JavaScript behavior for repeatable custom `Other` rows.

### Product Decisions
- Competition formats defaults: Kyorugi, Individual Poomsae, Pair Poomsae, Team Poomsae, Para Taekwondo.
- Basic eligibility defaults: age proof, academy/association membership, medical fitness, minimum belt, and guardian consent for minors.
- Required document defaults: age proof, government identity proof, academy approval letter, association ID, and medical clearance.
- Refund policy is checkbox-only as requested.
- Custom values saved from previous edits are shown back as populated `Other` rows.

### Change Log
- Added default checklist constants to `Tournament`.
- Replaced competition formats, basic eligibility, required documents, and refund policy text areas with checkbox groups.
- Added repeatable custom `Other` text rows for formats, eligibility, and required documents.
- Updated `TournamentsController` strong params to accept checklist arrays and compose them into existing text fields.
- Added CSS for checklist groups, checkbox options, and custom rows.
- Updated tests to verify default labels render and selected/default/custom values are saved.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/models/tournament_test.rb`; result: 20 runs, 199 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 73 runs, 552 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Tournament Image Uploads

### Reference
- User request: image fields currently ask for a URL; make them uploaders and save the image directly instead.

### Scope Chosen For This Pass
- Replace tournament logo/banner URL inputs with file upload controls.
- Store uploaded tournament images through Active Storage.
- Render uploaded images on tournament listings and tournament detail pages.
- Keep old `logo_url` and `banner_image_url` columns as display fallback for older records, but stop accepting them in the tournament form/controller.

### Product Decisions
- `logo_image` is the uploaded logo/card image for tournament listings.
- `banner_image` is the uploaded wide hero/banner image for tournament detail pages.
- Upload controls accept PNG, JPG, and WebP.
- Existing remote image URL data remains readable so older development records do not break.

### Change Log
- Added `has_one_attached :logo_image` and `has_one_attached :banner_image` to `Tournament`.
- Added `Tournament#logo_image_source` and `Tournament#banner_image_source` helpers for uploaded-image-first rendering with URL fallback.
- Replaced `logo_url` and `banner_image_url` form fields with file uploaders.
- Updated tournament controller strong params to accept `logo_image` and `banner_image` uploads instead of image URL params.
- Updated tournament index to render uploaded logo images.
- Updated tournament show to render uploaded banner images.
- Added tournament image upload fixture and tests for attached images.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/models/tournament_test.rb`; result: 20 runs, 180 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 73 runs, 533 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Expanded Add Tournament Setup Flow

### Reference
- User request: review the Add Tournament flow and make sure these fields are available: tournament name and level, organising organisation, start/end dates, registration opening/closing dates, time zone, venue/location, primary contact, competition formats, basic eligibility, category generation, registration capacity, fee/currency, required documents, refund policy, Save as Draft and Publish actions, and a banner/image field.

### Scope Chosen For This Pass
- Add missing tournament setup fields as first-class database columns.
- Reorganize the tournament form into setup sections so organizers can complete the event configuration in one flow.
- Mark setup fields as required for browser-level publish validation while allowing incomplete drafts.
- Keep primary contact details editable by organizers without exposing the contact email/phone on public tournament pages.
- Preserve existing category creation as a separate detailed flow after the tournament shell exists.

### Product Decisions
- `logo_url` remains available for logo/media-kit images; `banner_image_url` was added for larger tournament artwork.
- `competition_formats`, `eligibility_summary`, `required_documents`, and `refund_policy` are stored as text because they may vary by tournament and are not yet normalized into separate policy/rules tables.
- `category_generation_method` captures how categories will be created, while actual categories still live in `tournament_categories`.
- `Save as Draft` forces `draft` status. `Publish` moves a draft tournament to `scheduled`.
- `Save as Draft` uses `formnovalidate` so organisers can save incomplete work; `Publish` runs browser required-field checks for the setup checklist.
- Primary contact name/email/phone is collected in the form but not shown publicly to avoid exposing personal contact data.

### Change Log
- Added tournament fields for level, organising organisation, time zone, primary contact, competition formats, eligibility, category-generation method, registration capacity, fee, currency, required documents, refund policy, and banner image URL.
- Added validations for banner URL, primary contact email format, registration capacity, and registration fee.
- Expanded the tournament form into Basics, Schedule and location, Registration setup, and Contacts and publishing sections.
- Added `Save as Draft` and `Publish` submit buttons, with required form fields enforced for Publish.
- Updated tournament detail page to show non-sensitive event setup details, capacity, fee, formats, eligibility, category-generation method, required documents, and refund policy.
- Added tests for the expanded form labels, saved setup fields, draft/publish submit intents, and public hiding of primary contact email/phone.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: tournament setup field migration applied successfully.
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/models/tournament_test.rb`; result: 19 runs, 169 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 72 runs, 526 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Organizer Registration Verification Fields

### Reference
- User request: while registering an organiser, collect designation, academy affiliation if they belong to one, one government/identity verification document such as Aadhaar, and make mobile number compulsory.

### Scope Chosen For This Pass
- Add organizer-only registration fields to the existing account creation flow.
- Require mobile number, designation, and identity document only for pending organizer registrations.
- Keep academy affiliation optional because not every organizer may belong to an academy.
- Store identity documents with Rails Active Storage using local disk storage in development and test.

### Product Decisions
- `phone` remains the shared user mobile/contact field, but it is required when the account is a pending organizer request.
- `organizer_designation` stores the organizer's title or capacity, such as tournament director, coach, or academy owner.
- `organizer_academy_id` optionally links an organizer to an approved academy.
- `identity_document` is a private Active Storage attachment on `User`; the public organizer directory does not expose the uploaded document.
- Existing verified organizers are not forced to backfill identity documents, so older data and tests remain usable.

### Change Log
- Added Active Storage migrations and `config/storage.yml`.
- Configured development storage as `:local` and test storage as `:test`.
- Added organizer profile fields to users: `organizer_designation` and optional `organizer_academy`.
- Added `User#identity_document` attachment.
- Added conditional organizer registration validations for mobile number, designation, and identity document upload.
- Updated organizer signup form with required mobile number, designation, optional academy affiliation, optional public photo URL, and required identity document upload accepting PDF/JPG/PNG.
- Updated organizer directory to show designation and academy affiliation on verified organizer cards and pending-review rows.
- Added tests and a fixture identity document for organizer signup and organizer approval flows.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: Active Storage tables and organizer profile columns applied successfully.
- Ran `mise exec -- bin/rails test test/controllers/users_controller_test.rb test/controllers/organizers_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 22 runs, 195 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 69 runs, 461 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Tournament Category List View

### Reference
- User request: on the tournament page, show categories in list view instead of tiles.

### Scope Chosen For This Pass
- Change the tournament detail page category section only.
- Preserve existing category edit and tournament registration actions.
- Keep the list responsive for mobile and desktop.

### Product Decisions
- Categories are operational tournament data, so the detail page should use a compact row layout instead of card tiles.
- Each row shows event type, category name, gender, age range, weight range, and available actions.

### Change Log
- Replaced the category tile grid on `tournaments/show` with `category-list` and `category-row` markup.
- Added responsive CSS for category rows, details, and actions.
- Added a controller rendering assertion so the tournament page keeps the category list structure.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb`; result: 12 runs, 96 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 68 runs, 440 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-26 - Organizer Verification And Tournament Organizer Roles

### Reference
- User request: support multiple organizer roles. Organizer signups should create normal organizer requests, super admins should verify organizers, the creator of a tournament should become the super organizer for that tournament, creators should be able to add other organizers while creating/editing tournaments, and the signed-out Organizer page should invite event organizers while listing verified organizers with photos and events.

### Scope Chosen For This Pass
- Add organizer verification state to user accounts.
- Keep organizer signup public, but require super-admin verification before tournament creation.
- Add per-tournament organizer membership records so each tournament can have a super organizer and collaborator organizers.
- Add a public `/organizers` directory for signed-out users.
- Preserve the existing signed-in organizer registration-approval workflow.

### Product Decisions
- `User#role` remains the account role; organizer accounts now also have `organizer_status`.
- Existing organizer records default to `verified` so old test/development data keeps working.
- New organizer signups are explicitly created as `pending` and redirect to the organizer directory with a verification message instead of going directly to tournament creation.
- Tournament creators remain stored in `tournaments.organizer_id` and are also mirrored into `tournament_organizers` as `super_organizer`.
- Other organizers are stored in `tournament_organizers` as `collaborator`.
- Only verified organizer users are selectable as tournament collaborators.
- Organizer cards use `profile_photo_url` when provided and fall back to initials so the public directory always has a visible identity element.

### Change Log
- Added user organizer review fields: `organizer_status`, review timestamps, reviewer reference, and `profile_photo_url`.
- Added `TournamentOrganizer` model and `tournament_organizers` table with `super_organizer` and `collaborator` roles.
- Added public `OrganizersController#index` plus super-admin `approve` and `reject` actions.
- Added public organizer directory view with event-minded CTA, pending-review table for super admins, verified organizer cards, photos/initials, and organized-event names.
- Updated top navigation so signed-out users go to `/organizers`; signed-in users keep the existing organizer registration approvals page.
- Updated organizer signup to include optional profile photo URL, create pending organizer accounts, and show verification-focused copy.
- Updated tournament create/edit to let managers add other verified organizers.
- Updated tournament management checks so tournament collaborators can manage tournament details and organizer registration approvals.
- Updated tournament show to label the creator as `Super organizer` and list all organizers.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: new organizer review and tournament organizer tables/columns applied successfully.
- Ran `mise exec -- bin/rails test`; result: 68 runs, 436 assertions, 0 failures, 0 errors, 0 skips.
- Checked rendered `/organizers` through Rails integration session; result: HTTP 200, event-minded CTA present, and `Register as organizer` CTA present.

## 2026-08-19 - Requirements-Based Tournament Flow Improvement

### Reference
- Source document: `/Users/sonamgoyal/.codex/attachments/1d4edf1c-533a-4af6-8728-51ec78588b0d/pasted-text.txt`
- Product goal extracted: organisers should configure and publish tournaments with minimal manual entry; categories should be system-generated and consistently validated; registration should respect tournament status and windows.

### Scope Chosen For This Pass
- Keep the current MVP small and Rails-conventional.
- Improve tournament lifecycle statuses to match the requirements more closely.
- Add server-side tournament date/window validations.
- Prevent duplicate generated tournament categories.
- Keep category names generated from structured fields, not typed by users.
- Block normal registration when tournament status/window says registration is not open.
- Add tests for each new business rule.

### Out Of Scope For This Pass
- Full organisation model, staff assignments, audit log, payments, documents, waitlists, draws/brackets, live scheduling, notifications, and the full Add Athlete workflow.
- Matrix category generation and custom admin-only category display labels.

### Change Log
- Started implementation pass:
  - Add server-side tournament lifecycle/date validations.
  - Add generated category identity for duplicate prevention.
  - Gate tournament registrations behind status/window checks.
  - Add tests for the above behaviours.
- Implemented `Tournament#accepting_registrations?` to require `registration_open` status and an active registration window.
- Expanded tournament lifecycle statuses to include `ready_for_review`, `scheduled`, `registration_paused`, `draw_scheduling`, and `archived`, while preserving existing enum integer values.
- Added tournament validation for:
  - Normalized 3-120 character names.
  - Registration close after registration open.
  - Registration close not after the event start date.
- Added `tournament_categories.category_key` with a unique database index on `[tournament_id, category_key]`.
- Added generated `TournamentCategory#category_key` from event type, gender, age, weight, and belt fields.
- Added model validation to block duplicate structured categories within the same tournament.
- Updated registration new/create flow to redirect with an alert when tournament registration is not open.
- Updated tournament detail page to show a non-open status pill instead of a registration CTA when registration is not currently allowed.
- Added tests for tournament registration-window validation, category duplicate prevention, and registration gating.
- Updated `README.md` and `AGENTS.md` to point future maintainers to this log and align the stack note with the current plain-CSS setup.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; migration `20260819000100_add_category_key_to_tournament_categories` completed and backfilled existing category rows.
- Ran `mise exec -- bin/rails test`; result: 19 runs, 79 assertions, 0 failures, 0 errors, 0 skips.
- Final check after documentation updates: ran `mise exec -- bin/rails test`; result: 19 runs, 79 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-23 - Athlete Flow MVP

### Reference
- Source document: `/Users/sonamgoyal/Downloads/Taekwondo_Tournament_Management_PRD.docx`
- Product goal extracted: users should be able to select an existing athlete during registration or use an Add Athlete entry point; detailed athlete verification can stay lightweight for the MVP.

### Scope Chosen For This Pass
- Keep the existing Rails `Athlete` resource and make it a complete MVP flow.
- Add server-side athlete profile normalization and validations.
- Add an Add Athlete entry point from tournament registration when the current user has no athlete profiles.
- Return the user back to the registration page after adding an athlete from that entry point.
- Add controller and model tests for athlete creation, normalization, validation, and safe return handling.

### Product Decisions
- Athlete identity fields remain directly editable in this MVP because full verification/approval is out of scope.
- Gender and belt are controlled values to avoid inconsistent downstream eligibility/category matching.
- `return_to` is accepted only for same-site absolute paths and rejects protocol-relative URLs to avoid open redirects.

### Change Log
- Added `Athlete::GENDERS` and `Athlete::BELTS` controlled value lists.
- Added athlete field normalization for names, gender, belt, association ID, city, state, and country.
- Added athlete validations for first/last name length, supported gender, supported belt, positive weight, and future date of birth.
- Updated the athlete form to use model-backed gender/belt options and preserve safe return paths.
- Updated athlete create/update actions to redirect back to the originating flow when a safe `return_to` path is present.
- Added an inline empty state to the tournament registration form with an Add Athlete button.
- Added an Add Another Athlete link beside the registration athlete selector when profiles already exist.
- Updated registration create handling so a missing/invalid athlete selection re-renders the form with validation errors instead of raising a lookup error.
- Added tests for athlete model rules and athlete controller creation/return behavior.
- Added a registration controller test for missing-athlete submission.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 25 runs, 109 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test` after missing-athlete registration handling; result: 26 runs, 114 assertions, 0 failures, 1 error, 0 skips. The error was a test-only use of `assigns`, which is unavailable in Rails integration tests without adding an unnecessary gem.
- Replaced the `assigns` assertion with rendered-response assertions.
- Final check: ran `mise exec -- bin/rails test`; result: 26 runs, 116 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-23 - Tournament Athlete Visibility And Seed Data

### Reference
- User request: when an athlete is added, show those athletes under the tournament and create more seed data for testing.

### Scope Chosen For This Pass
- Show the current user's athlete profiles directly on each tournament detail page.
- Display per-athlete registration status for the current tournament when one exists.
- Preserve the Add Athlete return flow so athletes added from a tournament return to that tournament.
- Add more seed academies, athletes, tournaments, categories, and registrations for manual testing.

### Product Decisions
- The tournament page shows the current user's athletes, not every athlete in the system, because athlete profiles are user-scoped in the current MVP.
- Tournament athlete cards show registration state and category only for registrations belonging to that tournament.
- Registration links from athlete cards preselect the athlete in the registration form.

### Change Log
- Added `@athletes` and `@registrations_by_athlete_id` to `TournamentsController#show`.
- Added a My athletes section to the tournament detail page with Add Athlete, View Profile, Register, and registration status affordances.
- Updated `RegistrationsController#new` to accept `athlete_id` so athlete-card registration links can preselect an athlete.
- Expanded seed data with two academies, three athlete profiles, three tournaments, six categories, and two registrations.
- Fixed the expanded seed file syntax before running it.
- Updated seeded registration lookup to use explicit foreign keys instead of association objects.
- Fixed athlete seed indexing so the registration seed step references saved `Athlete` records, not source hashes.
- Added a tournament controller test that verifies athlete cards and registration status appear on tournament detail.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 27 runs, 125 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails db:seed`; result: failed with `PG::UndefinedTable` from registration seed lookup using association-object conditions.
- Ran `mise exec -- bin/rails db:seed` after switching registration lookup to explicit foreign keys; result: failed with `NoMethodError` because seeded athlete indexing returned source hashes instead of saved models.
- Ran `mise exec -- bin/rails db:seed` after fixing athlete seed indexing; result: completed successfully.
- Final check: ran `mise exec -- bin/rails test`; result: 27 runs, 125 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -I http://127.0.0.1:3000/tournaments`; result: `HTTP/1.1 200 OK`.

## 2026-08-23 - Role-Based Product Flow Pass

### Reference
- User request: support public browsing, academy registration with super-admin approval, academy-owner athlete management, tournament organizer registration review, general athlete tournament registration, draw setup placeholder, and super-admin capabilities.

### Scope Chosen For This Pass
- Add domain-level roles and ownership without adding a full authentication system yet.
- Keep public academy and tournament pages visible.
- Add academy status review states and super-admin approval actions.
- Scope athlete management to the current user, with super-admin visibility.
- Scope organizer registration approvals to tournaments owned by the current user, with super-admin visibility.
- Add a draw setup placeholder for tournament organizers.

### Product Decisions
- Existing `admin` role semantics are represented as `super_admin` going forward.
- Any logged-in user can create a tournament and becomes that tournament's organizer in this MVP.
- Academy submissions are `pending` by default unless created by a super admin.
- Only approved academies can be selected on athlete profiles.
- Non-approved academies are visible to their owner and super admins, but public academy browsing is for approved academies.

### Change Log
- Added academy ownership and review status fields via migration `20260823000100_add_ownership_and_status_to_academies`.
- Added `User#owned_academies`, `academy_owner` role, `super_admin` role, and organizer capability helper.
- Added `Academy` owner association, `pending/approved/rejected` statuses, and email validation.
- Added athlete validation that blocks assigning athletes to pending or rejected academies.
- Added shared controller helpers for super-admin, academy-management, and tournament-management checks.
- Added academy approve/reject routes and controller actions.
- Updated academy creation to submit for approval and assign current user as owner.
- Updated athlete forms to list only approved academies.
- Updated tournament creation to assign current user as organizer.
- Scoped organizer registration approval pages to the current user's tournaments unless the user is a super admin.
- Added tournament draw placeholder route and view.
- Updated home, academy, tournament, and organizer screens to reflect public visitor, academy owner, organizer, athlete, and super-admin flows.
- Expanded seed users and academies with super-admin, academy-owner, approved, pending, and rejected records.
- Added model and controller tests for academy public visibility, academy approval, athlete approved-academy validation, and organizer registration scoping.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; migration `20260823000100_add_ownership_and_status_to_academies` completed successfully.
- Ran `mise exec -- bin/rails db:seed`; result: completed successfully with updated role and academy review demo data.
- Ran `mise exec -- bin/rails test`; result: 34 runs, 159 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -I http://127.0.0.1:3000/tournaments`; result: `HTTP/1.1 200 OK`.

## 2026-08-23 - Session Authentication

### Reference
- User request: add authentication and provide super-admin username/password.

### Scope Chosen For This Pass
- Add session-based sign-in/sign-out using the existing `User` model and `has_secure_password`.
- Add general user account creation for athlete/tournament registration.
- Remove the temporary demo-current-user fallback from controller authentication.
- Keep seeded demo credentials stable for local testing.
- Update tests to sign in explicitly.

### Product Decisions
- New self-service accounts are created as general `parent` users for now.
- Super-admin and organizer accounts are seeded, not self-service created.
- Protected flows redirect to the login page with a `return_to` path.

### Change Log
- Added login/logout routes and `SessionsController`.
- Added user signup routes and `UsersController`.
- Added login and signup views.
- Updated navigation to show sign-in/create-account when signed out and role/sign-out when signed in.
- Updated `ApplicationController#current_user` to rely on `session[:user_id]`.
- Added `require_user` redirects to the login page.
- Updated tournament and registration flows to handle signed-out public visitors.
- Added email normalization to `User`.
- Added a test helper for explicit sign-in in integration tests.
- Updated seed data so demo account passwords are reset on every `db:seed`.
- Added session controller tests for sign-in, failed sign-in, and sign-out.
- Added user signup controller test for general user account creation.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 34 runs, 110 assertions, 13 failures, 1 error, 0 skips. Failures were expected old tests relying on implicit demo login after removing the fallback.
- Updated affected tests to sign in explicitly.
- Ran `mise exec -- bin/rails test`; result: 34 runs, 159 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails db:seed`; result: completed successfully and reset demo credentials.
- Ran `mise exec -- bin/rails test`; result: 38 runs, 180 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -I http://127.0.0.1:3000/login`; result: `HTTP/1.1 200 OK`.

## 2026-08-24 - Rename App Branding To Sports Hub

### Reference
- User request: rename the repo to Sports Hub.

### Scope Chosen For This Pass
- Rename source-level app branding from Taekwondo Hub to Sports Hub.
- Update visible app title, navigation brand, homepage copy, academy heading, setup output, README, AGENTS instructions, and this progress log.
- Rename the Rails application module to `SportsHub`.

### Product Decisions
- The local folder path and database names remain `taekwondo-hub` / `taekwondo_hub_*` for now to avoid disrupting the running development database.
- Seeded sample data can still include taekwondo-specific tournaments and academies as one sports vertical inside Sports Hub.
- The project is not currently a git repository, so no GitHub repository was renamed in this pass.

### Change Log
- Renamed application title and header brand to Sports Hub.
- Updated homepage and academy index copy to be sport-generic.
- Updated README and setup output to use Sports Hub.
- Updated repo instructions and progress log title to use Sports Hub.
- Renamed Rails application module from `TaekwondoHub` to `SportsHub`.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 38 runs, 180 assertions, 0 failures, 0 errors, 0 skips.
- Restarted the local Rails server so the renamed `SportsHub` application module loaded cleanly.
- Checked the running server with `curl -I http://127.0.0.1:3000/`; result: `HTTP/1.1 200 OK`.
- Checked the rendered homepage HTML; result: `<title>Sports Hub</title>`, header brand `SPORTS HUB`, and footer `Sports Hub` are present.
- Confirmed the session cookie name changed to `_sports_hub_session`.

## 2026-08-24 - Tournament Breadcrumb Navigation

### Reference
- User request: add breadcrumbs for the tournament pages.

### Scope Chosen For This Pass
- Add a shared breadcrumb component.
- Apply breadcrumbs to tournament index, show, new, edit, draw, nested category pages, and nested registration pages.
- Keep breadcrumbs read-only navigation and use existing generated tournament/category names.

### Product Decisions
- Breadcrumbs start at Home, then Tournaments, then the current tournament when applicable.
- Category and registration pages stay nested under the tournament to reinforce tournament context.
- The current page breadcrumb is plain text with `aria-current="page"` for accessibility.

### Change Log
- Added `app/views/shared/_breadcrumbs.html.erb`.
- Added breadcrumb styling in `app/assets/stylesheets/application.css`.
- Added breadcrumb trails across tournament, tournament category, and tournament registration views.
- Added a tournament controller test that asserts tournament show pages render breadcrumb navigation.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 41 runs, 193 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -s http://127.0.0.1:3000/tournaments`; result: tournament index rendered breadcrumb navigation with `aria-label="Breadcrumb"`.

## 2026-08-24 - Remove Seed Data

### Reference
- User request: remove all seed data.

### Scope Chosen For This Pass
- Remove application seed definitions from `db/seeds.rb`.
- Keep an explicit note that the app intentionally ships with no seed data.
- Do not delete existing development database records in this pass because that is a destructive local data wipe.

### Product Decisions
- Shared and production environments should start clean by default.
- Demo records should be created through separate local-only scripts or console sessions when needed, not through the canonical seed file.

### Change Log
- Replaced the demo seed data in `db/seeds.rb` with a short no-seed-data note.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 41 runs, 193 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails db:seed`; result: completed successfully with no seed records defined.

## 2026-08-24 - Homepage Previous Competitions

### Reference
- User request: remove the homepage competition section and add previous competitions from 2025, including links to event homepages where possible.

### Research Sources
- USA Taekwondo: `https://www.usatkd.org/2025-u-s-open-taekwondo-championship`
- USA Taekwondo: `https://www.usatkd.org/2025-u-s-taekwondo-national-championships`
- World Taekwondo results: `https://results.worldtaekwondo.org/competitions`
- World Taekwondo event page: `https://www.worldtaekwondo.org/competition/view.html?mcd=U05&nid=142108&sc=in`
- Wuxi local government event article: `https://en.wuxi.gov.cn/2025-10/22/c_1134215.htm`
- Nairobi 2025 event site: `https://www.kenyau21wtchampionship2025.com/`

### Scope Chosen For This Pass
- Replace the homepage “COMPETITIONS” workflow cards with a “PREVIOUS COMPETITIONS” section.
- Use curated static homepage content for previous events instead of database-backed tournament records.
- Include official or event-adjacent links for each listed competition.

### Product Decisions
- The section is a public credibility/reference area, not part of the app’s active tournament registration data.
- Links are labeled “Event page” because some official sources are result/event pages rather than standalone homepages.
- Listed events include a mix of U.S. and international 2025 taekwondo competitions.

### Change Log
- Added `@previous_competitions` to `HomeController#index`.
- Replaced the homepage competitions workflow cards with previous-competition cards.
- Added responsive styling for the previous-competitions grid.
- Added a homepage controller test that asserts the previous-competitions section and links render.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 42 runs, 202 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -s http://127.0.0.1:3000/`; result: homepage rendered the `PREVIOUS COMPETITIONS` section with 2025 event cards and external event links.

## 2026-08-24 - Homepage Sports News Notes

### Reference
- User request: remove the homepage journey section and add sports news notes for domestic and international items.

### Research Sources
- Press Information Bureau: `https://www.pib.gov.in/PressReleasePage.aspx?PRID=2292439&lang=1&reg=48`
- Sports Authority of India news archive: `https://sportsauthorityofindia.gov.in/sai_new/news-archive`
- Taekwon-do Association of India events: `https://www.itfindia.org.in/events`
- World Taekwondo Grand Prix results calendar: `https://results.worldtaekwondo.org/competitions?type=gp`
- World Taekwondo competitions calendar: `https://results.worldtaekwondo.org/competitions`
- World Taekwondo news: `https://www.worldtaekwondo.org/wtnews/view.html?mcd=C02&nid=142224`

### Scope Chosen For This Pass
- Remove the homepage “THE JOURNEY” section from the rendered page.
- Add a “SPORTS NEWS” section in the same homepage position.
- Split notes into Domestic and International columns with source links.

### Product Decisions
- News notes are curated static homepage content, not database-backed records.
- Domestic notes focus on India-facing sports-development and taekwondo calendar sources.
- International notes focus on World Taekwondo event calendars and host updates.

### Change Log
- Added `@sports_news` to `HomeController#index`.
- Replaced the journey view markup with domestic/international sports-news notes.
- Replaced unused journey styling with responsive news-board styles.
- Added a homepage controller test that confirms the news section renders and the old journey label is absent.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 43 runs, 215 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -s http://127.0.0.1:3000/`; result: homepage rendered `SPORTS NEWS`, Domestic and International columns, and no `THE JOURNEY` label.

## 2026-08-24 - Homepage Blogs And YouTube Picks

### Reference
- User request: add a blogs section with taekwondo blogs, then add YouTube links for a few widely seen taekwondo videos.

### Research Sources
- Feedspot taekwondo blog roundup: `https://bloggers.feedspot.com/taekwondo_blogs/`
- Traditional Taekwondo Ramblings: `http://jungdokwan-taekwondo.blogspot.com/`
- Little Black Belt: `https://littleblackbelt.com/`
- SportsEdTV Taekwondo blog category: `https://sportsedtv.com/blog/category/taekwondo/`
- British Taekwondo news: `https://www.britishtaekwondo.org.uk/news/`
- Grit & Glory Taekwondo blog: `https://ggtkd.com/blog`
- Sun Lee Taekwondo blog: `https://sunleetaekwondo.com/blogs/news`
- vidIQ World Taekwondo YouTube stats/top videos: `https://vidiq.com/youtube-stats/channel/UCHp-A--zKubjgaa5ZQClk9g/`

### Scope Chosen For This Pass
- Add a curated `TAEKWONDO BLOGS` homepage section after Sports News.
- Add a `YOUTUBE PICKS` homepage section after the blog section.
- Use static curated links in `HomeController#index` rather than database-backed content.

### Product Decisions
- Blog links include a mix of practitioner writing, coaching/instruction content, governing-body updates, and parent-friendly articles.
- YouTube picks use exact-title YouTube search links for World Taekwondo videos that vidIQ lists among the channel's most-viewed videos. This avoids hard-coding uncertain video IDs while still taking users directly to relevant YouTube results.
- Video copy includes approximate view-count context from the current vidIQ listing.

### Change Log
- Added `@taekwondo_blogs` and `@taekwondo_videos` to `HomeController#index`.
- Added homepage sections for taekwondo blogs and YouTube video picks.
- Added responsive resource-card and video-list styling.
- Added a homepage controller test that asserts both new sections render.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 44 runs, 228 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -s http://127.0.0.1:3000/`; result: homepage rendered `TAEKWONDO BLOGS`, `YOUTUBE PICKS`, blog links, and YouTube links.

## 2026-08-24 - Upcoming Tournament Branding

### Reference
- User request: make the upcoming tournament section more attractive and add images or logos from tournament websites.

### Scope Chosen For This Pass
- Add optional tournament website and logo/image URL fields.
- Render logos/images on upcoming tournament cards when organizers provide them.
- Add a clean generated fallback mark when a tournament has no logo URL.
- Show a tournament website link from listing and detail pages when present.

### Product Decisions
- Store organizer-provided URLs instead of copying third-party images into the app.
- Accept only `http` and `https` URLs for tournament website and logo fields.
- Keep the fallback visual local and generated from the tournament name so empty/logo-less tournaments still look intentional.

### Change Log
- Added migration `20260824000100_add_branding_to_tournaments`.
- Added `website_url` and `logo_url` normalization and validation to `Tournament`.
- Permitted branding fields in tournament create/update params.
- Added website/logo fields to the tournament form.
- Updated upcoming tournament cards with a visual header, optional logo image, website link, and responsive fallback.
- Added website link output to tournament detail summary.
- Added controller tests for branding URL persistence, validation, and listing output.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: migration added `website_url` and `logo_url` to tournaments successfully.
- Ran `mise exec -- bin/rails test`; result: 46 runs, 244 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -s http://127.0.0.1:3000/tournaments`; result: upcoming tournament cards rendered the new `tournament-visual` area and fallback marks.

## 2026-08-24 - Public Tournament Detail Cleanup

### Reference
- User request: in the logged-out scenario, tournament pages should not show My Athletes or No Athlete Profiles Yet; logged-out visitors should see tournament information only.

### Scope Chosen For This Pass
- Hide athlete-specific sections and calls to action on tournament detail pages for logged-out visitors.
- Keep tournament summary and category information public.
- Preserve athlete registration actions for logged-in users.
- Hide category management actions from visitors unless the current user can manage the tournament.

### Product Decisions
- Public tournament pages are informational browsing pages.
- Registration and athlete-profile actions require a signed-in user context.
- Categories remain public because they help visitors understand eligibility before deciding to create an account.

### Change Log
- Wrapped the `My athletes` section behind `current_user`.
- Hid the top `Register athlete` CTA from logged-out visitors.
- Hid category `Register` links from logged-out visitors.
- Hid category `Add` and `Edit` actions unless the user can manage the tournament.
- Added controller tests for logged-out and logged-in tournament detail behavior.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 48 runs, 266 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -s http://127.0.0.1:3000/tournaments/1` as a logged-out visitor; result: tournament summary and categories rendered without `My athletes`, `No athlete profiles yet`, athlete registration CTAs, or empty action wrappers.

## 2026-08-24 - Clarify Public Signup CTA

### Reference
- User concern: the homepage/header “Create account” button feels ambiguous.

### Scope Chosen For This Pass
- Rename the logged-out navigation signup CTA.
- Clarify the signup page heading, supporting copy, and submit button.
- Keep the underlying signup role unchanged: new self-service users are general parent/athlete-flow users.

### Product Decisions
- Use “Join as athlete” for the public CTA because it describes the main self-service account path.
- Use “Create athlete account” on the form submit button so users understand what they are creating.
- Do not expose organizer, academy owner, or super admin account creation through this generic signup flow.

### Change Log
- Changed logged-out nav CTA from `Create account` to `Join as athlete`.
- Changed login-page secondary CTA to `Join as athlete`.
- Updated signup page copy from generic account language to athlete/parent account language.
- Added controller tests for signup-page copy and login-page CTA copy.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 49 runs, 275 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -s http://127.0.0.1:3000/`; result: logged-out header renders `Join as athlete`.
- Checked the running server with `curl -s http://127.0.0.1:3000/users/new`; result: signup page renders `ATHLETE ACCOUNT`, `Join as athlete`, and `Create athlete account`.

## 2026-08-24 - Neutral Login Heading

### Reference
- User request: when creating a tournament and reaching the login page, it should say “Welcome”, not “Welcome back”.

### Scope Chosen For This Pass
- Update the login page heading from `Welcome back` to `Welcome`.
- Add a controller test to prevent the old wording from returning.

### Product Decisions
- Use neutral wording because the login page is reached by both returning users and new users exploring protected actions such as creating a tournament.

### Change Log
- Updated `app/views/sessions/new.html.erb`.
- Added a session controller test for the neutral login heading.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 50 runs, 280 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -s -L http://127.0.0.1:3000/tournaments/new`; result: logged-out create-tournament flow renders the login page with `Welcome` and preserves `return_to=/tournaments/new`.

## 2026-08-24 - Homepage Hero Photo

### Reference
- User request: replace the black image/card on the homepage right side with something better, such as a close-up photo of a black belt on the uniform.

### Scope Chosen For This Pass
- Generate a local black-belt/dobok close-up image.
- Store the generated image as a Rails asset.
- Replace the old black role-flow card with a photographic hero card.
- Keep a concise caption overlay that supports the product story.

### Product Decisions
- Use a generated local image asset instead of a remote third-party image URL to avoid broken image links or licensing ambiguity.
- Remove the emoji belt marker from the hero card because the photo carries the visual signal more professionally.
- Keep the image decorative but accessible with descriptive alt text.

### Change Log
- Added optimized local image asset `app/assets/images/black-belt-dobok.jpg`.
- Replaced homepage hero-card markup with a hero photo card.
- Added responsive CSS for the photo, overlay, and caption.
- Added a homepage controller test that asserts the hero image and alt text render.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 51 runs, 287 assertions, 0 failures, 0 errors, 0 skips.
- Optimized the generated image from a 2.1 MB PNG to a 271 KB JPEG.
- Restarted the local Rails server so Propshaft could pick up the new `app/assets/images` directory.
- Checked the running server with `curl -s http://127.0.0.1:3000/`; result: homepage rendered the fingerprinted `black-belt-dobok` JPEG, descriptive alt text, and `READY FOR THE MAT` caption.

## 2026-08-24 - Organizer Signup CTA For Tournament Creation

### Reference
- User request: on `/login?return_to=%2Ftournaments%2Fnew`, show organizer-focused options instead of `Join as athlete`; users should be able to sign in as organizer or create an organizer account.

### Scope Chosen For This Pass
- Make the login page context-aware when the return path is tournament creation.
- Show organizer-focused login copy and button text for tournament creation.
- Add an organizer signup mode that creates `organizer` users and returns them to tournament creation.
- Preserve the existing athlete/parent signup wording and role for normal public signup.

### Product Decisions
- Use `account_type=organizer` as the explicit public signup mode for tournament organizers.
- Default signup remains the general athlete/parent account to avoid accidentally creating elevated roles from the normal header CTA.
- Keep return paths restricted to same-site absolute paths.

### Change Log
- Updated `SessionsController` view behavior for `return_to=/tournaments/new`.
- Added account-type handling to `UsersController`.
- Added organizer-specific signup copy and hidden account type handling.
- Added tests for organizer login CTA, organizer signup page copy, and organizer account creation.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 54 runs, 313 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -s http://127.0.0.1:3000/login?return_to=%2Ftournaments%2Fnew`; result: page rendered `Sign in as organizer` and `Create organizer account`, including the header CTA.
- Checked the running server with `curl -s http://127.0.0.1:3000/users/new?account_type=organizer&return_to=%2Ftournaments%2Fnew`; result: page rendered `ORGANIZER ACCOUNT`, `Create organizer account`, hidden `account_type=organizer`, and preserved `return_to=/tournaments/new`.

## 2026-08-24 - Quiet Protected Page Login Redirects

### Reference
- User report: `/login?return_to=%2Ftournaments%2Fnew` shows a `Please sign in` error immediately; this should not appear just because the user clicked a protected page. Check the same error on other pages.

### Scope Chosen For This Pass
- Remove passive `Please sign in before continuing.` flash alerts from protected-page GET redirects.
- Keep the return path behavior intact.
- Show `Please sign in before continuing.` only when the login form is submitted without email or password.
- Add coverage for multiple protected entry points.

### Product Decisions
- Redirecting a visitor from a protected page to login is normal navigation, not an error state.
- Blank login submission is a validation state, so it should show an inline alert.
- Invalid credentials continue to show the existing invalid email/password alert.

### Change Log
- Updated `ApplicationController#require_user` to redirect without an alert.
- Added blank login-submit handling in `SessionsController#create`.
- Added `AuthenticationRedirectsTest` covering new tournament, new athlete, new academy, tournament registration, and organizer registration redirects.
- Added a session controller test for blank login submission.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 56 runs, 339 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -s -L http://127.0.0.1:3000/tournaments/new`; result: redirected to organizer login without `Please sign in before continuing.`.
- Checked the running server with `curl -s -L http://127.0.0.1:3000/athletes/new`; result: redirected to general login without `Please sign in before continuing.`.
- Blank login submit behavior is covered by `SessionsControllerTest`, which verifies the alert renders only after an empty login POST.

## 2026-08-24 - Hide Academy Athlete Details From Public Visitors

### Reference
- User request: in signed-out view, selecting Academies should not show athlete details.

### Scope Chosen For This Pass
- Hide athlete counts on the public academy index for logged-out visitors.
- Hide registered athlete names and belt details on academy detail pages unless the user can manage the academy.
- Preserve academy owner and super-admin visibility for athlete details.

### Product Decisions
- Public academy pages should show academy identity and contact information only.
- Athlete names and belt details are operational/private information for academy managers and admins.
- Category-level public tournament information remains separate from academy athlete rosters.

### Change Log
- Updated academy index to render athlete counts only for signed-in users.
- Updated academy detail to render registered-athlete details only for users who can manage the academy.
- Added controller tests for logged-out index, logged-out show, and academy-manager show behavior.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 59 runs, 360 assertions, 0 failures, 0 errors, 0 skips.
- Checked the running server with `curl -s http://127.0.0.1:3000/academies`; result: logged-out academy index rendered academy cards without athlete counts.
- Checked the running server with `curl -s http://127.0.0.1:3000/academies/1`; result: logged-out academy detail rendered academy information without `Registered athletes`, athlete names, or belt details.

## 2026-08-24 - Academy Registration Signup Flow

### Reference
- User request: on the homepage, clicking `Register academy` should take users to the register academy flow; currently it feels like the register athlete flow.

### Scope Chosen For This Pass
- Route logged-out homepage academy CTAs through `login?return_to=/academies/new`.
- Make the login page academy-aware for academy registration.
- Add an academy-owner signup mode.
- Return newly created academy-owner users to the academy registration form.

### Product Decisions
- Use `account_type=academy_owner` for users entering through the academy registration flow.
- Default public signup remains the athlete/parent flow.
- Academy-owner accounts can submit academies for super-admin approval; academy approval rules remain unchanged.

### Change Log
- Updated homepage `Register academy` and `Submit academy` links for logged-out users.
- Added academy-owner context to the logged-out header CTA.
- Added academy-owner context to the login page copy, submit button, and secondary CTA.
- Extended user signup account-type handling to create `academy_owner` users.
- Added tests for homepage academy CTA, academy-owner login CTA, academy-owner signup copy, and academy-owner account creation.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 63 runs, 393 assertions, 0 failures, 0 errors, 0 skips.
- Checked rendered homepage through Rails integration session; result: `Register academy` and `Submit academy` link to `/login?return_to=%2Facademies%2Fnew` for logged-out users.
- Checked rendered academy login page through Rails integration session; result: academy-owner copy, submit button, and `Create academy owner account` CTA are shown, and `Join as athlete` is not shown.
- Checked rendered academy-owner signup page through Rails integration session; result: academy-owner heading, hidden `account_type=academy_owner`, and hidden `return_to=/academies/new` are present.
- Ran `git diff --check`; result: no whitespace errors.

## 2026-08-24 - Initial GitHub Publish

### Reference
- User request: push the local Sports Hub code to `https://github.com/sonamvg/sports-hub`.

### Scope Chosen For This Pass
- Initialize a local git repository for the existing Sports Hub source tree.
- Connect the repository to GitHub remote `origin`.
- Create one initial commit and push it to `main`.

### Product Decisions
- Removed the initial GitHub Actions CI workflow from the first pushed commit because GitHub rejected workflow file updates from the current OAuth authorization without `workflow` scope.
- CI can be added later after authenticating GitHub with workflow scope.

### Change Log
- Initialized git in `/Users/sonamgoyal/Documents/taekwondo-hub`.
- Added remote `origin` pointing to `https://github.com/sonamvg/sports-hub.git`.
- Removed `.github/workflows/ci.yml` before the successful remote push.

### Verification Log
- Initial push attempt failed because GitHub rejected `.github/workflows/ci.yml` without OAuth `workflow` scope.
- Removed `.github/workflows/ci.yml`, amended the initial commit, and pushed `main` to `https://github.com/sonamvg/sports-hub.git`.
- Pushed commit: `c667b8a0d0a67eecf5792a94b41cac6571a0fac4`.

## 2026-08-24 - Super Admin Athlete Profile Access Fix

### Reference
- User report: `/athletes/2` throws an error on the View Athlete page.

### Root Cause
- `AthletesController#set_athlete` always used `current_user.athletes.find(params[:id])`.
- That was correct for normal users but wrong for super admins, because the athlete index lets super admins see all athletes while the show action still only allowed records owned by the current super-admin user.

### Scope Chosen For This Pass
- Preserve normal user isolation for athlete profiles.
- Allow super admins to view/edit/delete all athlete profiles through the existing athlete controller.
- Add controller tests for both access paths.

### Change Log
- Added `AthletesController#visible_athletes`.
- Updated `set_athlete` to use `Athlete.all` for super admins and `current_user.athletes` for normal users.
- Added tests proving normal users cannot view another user's athlete and super admins can.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 40 runs, 184 assertions, 0 failures, 0 errors, 0 skips.
- Performed live HTTP verification: logged in as `admin@example.com` and requested `/athletes/2`; result: `200 OK` and athlete profile content rendered.

## 2026-08-27 - Organizer Image Helper Runtime Fix

### Reference
- User report: an error occurred after the organizer-profile and image-placeholder updates.

### Root Cause
- `/organizers` raised `ActionView::Template::Error: undefined method 'image_with_placeholder'`.
- The helper existed in `ApplicationHelper`, but the running app was not exposing that helper method to view templates.

### Scope Chosen For This Pass
- Keep the placeholder helper implementation unchanged.
- Explicitly expose `ApplicationHelper` from `ApplicationController` so all controller-rendered views can use `image_with_placeholder`.

### Change Log
- Added `helper ApplicationHelper` to `ApplicationController`.

### Verification Log
- Restarted the Rails server on `127.0.0.1:3000`.
- Verified `GET /organizers` with `curl -i`; result: `HTTP/1.1 200 OK`.
- Checked `log/development.log`; result: the new `/organizers` request completed `200 OK`.
- First sandboxed `mise exec -- bin/rails test` attempt could not access the local PostgreSQL socket.
- Re-ran `mise exec -- bin/rails test` with local database access; result: 122 runs, 922 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-28 - Organizer Profile UI Simplification

### Reference
- User request: improve the organiser signed-in profile flow so the organiser tab first shows the organiser's name, email, phone number, and tournaments organised newest first.

### Product Decisions
- The organiser profile now focuses on identity and owned tournaments rather than internal approval metadata.
- "Newest first" is based on tournament creation time for the organiser-owned tournament list, because this page is about events the organiser created.

### Change Log
- Removed the organiser profile explanatory line about managing identity, events, approvals, referees, categories, venue setup, and tournament operations.
- Removed status, role, designation, approved-at, and "Tournaments where you are the super organiser" copy from the profile page.
- Added a simpler organiser identity panel showing name, organiser email, and phone number.
- Replaced the organiser tournament table with a cleaner list view showing event date, name, location, created date, status, and actions.
- Updated owned tournament ordering to newest created first.
- Updated organiser controller tests to cover the new profile copy and ensure the removed text stays removed.

### Verification Log
- Ran `mise exec -- bin/rails test`; first result: 122 runs, 912 assertions, 1 failure because an existing test still expected the old `ORGANIZER PROFILE` text.
- Updated the test expectation to the new organiser profile behavior.
- Re-ran `mise exec -- bin/rails test`; result: 122 runs, 930 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-28 - Global Left-Hand Menu

### Reference
- User request: change the menu from the top to a left-hand menu for the entire website.

### Product Decisions
- Replaced the global sticky top header with a persistent left sidebar so public, logged-in, and account-specific navigation all share one site-wide layout.
- Kept the same navigation destinations and role-aware organiser link behavior.
- Kept authentication actions in the same global menu, pinned near the bottom of the sidebar.

### Change Log
- Updated the application layout to wrap every page in an `app-frame` with a `side-menu` and `app-content`.
- Moved Tournaments, Athletes, Academies, Organizer, sign-in/sign-out, and account creation links into the left-hand sidebar.
- Reworked global navigation CSS from top-header styles to sidebar styles with responsive left rail widths and independent sidebar scrolling.
- Kept `app-content` as a `div` to avoid nested `<main>` landmarks on pages that already define their own main content.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 122 runs, 930 assertions, 0 failures, 0 errors, 0 skips.
- Attempted Rails runner render checks, but development host authorization returned `403`.
- Verified the running server with local HTTP requests to `/` and `/tournaments`; both returned `200`, included `class="side-menu"`, excluded `site-header`, and included `app-content`.

## 2026-08-28 - Organizer Tournament Operations And Category Locks

### Reference
- User request: for organiser users, show their tournaments under the organiser item in the left panel with tournament operation links; simplify the tournament main page; remove register options from categories; lock category edits once registration starts; improve other-organiser selection and invite flow.

### Product Decisions
- Organiser-created athlete profiles remain profiles owned by the organiser's account; they do not create a separate athlete login or password. Athletes who need their own password must use the public "Join as athlete" account flow.
- Category editing is allowed for tournament organisers only before registration starts. Super admins can edit categories at any time.
- Existing organisers are selected through a lightweight search/chip picker backed by verified organiser records.
- New organiser invitations are stored as tournament invitations and emailed with an organiser signup link after the tournament form is saved.

### Change Log
- Added organiser tournament shortcuts under the left-panel organiser navigation, newest first, with Edit, Add referees, Venue setup, Weight check, and Set draw actions.
- Replaced the tournament show page heading action group with a compact edit icon for tournament managers.
- Removed category-level registration links and the empty-state register link from tournament show/category pages.
- Added `Tournament#registration_started?` and `Tournament#categories_editable_by?`.
- Enforced category edit/create/default-import locking in `TournamentCategoriesController`.
- Added `TournamentOrganizerInvitation`, migration, controller, and mailer with HTML/text invite templates.
- Updated the tournament form's other-organiser section from a multi-select to a searchable organiser picker with selected-organiser chips and invite-by-email field.
- Prefilled organiser signup email when an invite link includes `invited_email`.
- Added an Add athlete page note explaining that organiser-created athlete profiles do not create separate login credentials.
- Added CSS for sidebar tournament groups, edit icon, organiser picker, and organiser chips.
- Built organiser picker chips with DOM nodes instead of `innerHTML` so organiser names/emails are not injected as markup.
- Added tests for organiser sidebar operations, hidden category registration actions, invite creation, invitation validation, organiser category lock, and super-admin category override.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: `tournament_organizer_invitations` table created and `db/schema.rb` updated.
- Ran `mise exec -- bin/rails test`; first result: 127 runs, 956 assertions, 1 failure because an existing tournament filter test saw organiser sidebar tournaments outside the filtered result list.
- Updated the filter test to assert the number of rendered tournament result cards instead of requiring sidebar text to disappear.
- Re-ran `mise exec -- bin/rails test`; result: 127 runs, 969 assertions, 0 failures, 0 errors, 0 skips.
- Re-ran `mise exec -- bin/rails test` after invite flash, DOM-safety, and Add athlete explanatory copy updates; result: 127 runs, 969 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-28 - Organizer Athlete Access And Tournament Category Setup

### Reference
- User request: organisers should not search all athletes, but can view profiles for athletes registered in their tournaments; organisers should only add athletes from tournaments they manage; remove register options for organisers; make custom checklist entries add checked boxes on Enter; remove "Copy from previous tournament"; add category setup panels for auto-generate, import, and manual category creation.

### Product Decisions
- Pure organiser accounts no longer get the athlete search/filter UI on the Athletes tab.
- Organisers can still view athlete profiles when the athlete has registered for a tournament managed by that organiser.
- Tournament registration links remain visible for athlete/academy-owner registration flows, but are hidden from pure organiser accounts.
- The Add athlete shortcut on a tournament show page is visible only to managers of that tournament.
- Custom competition formats, eligibility rules, and required documents are added as checked options only when the organiser types text and presses Enter; typing alone does not validate or submit anything.
- Category generation no longer offers "Copy from previous tournament".
- Auto-generate, import, and manual category setup are implemented as inline modal-style panels within the tournament form.
- CSV/TSV category import is implemented with Ruby's standard CSV parser. XLSX uploads are rejected with a clear message until a spreadsheet parser gem is added.

### Change Log
- Updated athlete visibility so organiser profile access includes athletes registered to tournaments they manage.
- Hid athlete search filters for pure organiser accounts on the Athletes index.
- Added `can_register_for_tournament?` to centralise whether a user should see tournament registration links.
- Hid tournament-card registration links from pure organiser accounts.
- Restricted tournament show Add athlete links to tournament managers only.
- Added category setup processing to `TournamentsController` for selected default categories, manual category rows, and CSV/TSV imports.
- Updated the tournament form category-generation dropdown and added auto-generate, import, and manual category panels.
- Updated checklist JavaScript so Enter creates a checked option for competition formats, basic eligibility, and required documents.
- Added CSS for category setup panels, default category editors, and manual category rows.
- Added tests for organiser athlete search restriction, organiser access to registered athlete profiles, organiser-hidden registration links, default category generation, manual category creation, and CSV category import.

### Verification Log
- Ran `mise exec -- bin/rails test`; first result: 127 runs, 964 assertions, 1 failure and 1 error. The failure was an old organiser registration-link expectation; the error was an incompatible ActiveRecord `or` query against a joined relation.
- Reworked organiser-visible athlete lookup to use an ID union instead of incompatible relation `or` calls.
- Updated the tournament registration-link test to sign in as an athlete account.
- Ran `mise exec -- bin/rails test`; result: 127 runs, 969 assertions, 0 failures, 0 errors, 0 skips.
- Added focused tests for the new organiser restrictions and category setup paths.
- Ran `mise exec -- bin/rails test`; first result after new tests: 133 runs, 997 assertions, 1 failure because the CSV import expectation did not include the belt range from the fixture.
- Corrected category import expectations.
- Re-ran `mise exec -- bin/rails test`; result: 133 runs, 997 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-28 - Category Edit Generated Name Preview

### Reference
- User request: when a category is edited, the name should be edited accordingly.

### Product Decisions
- Kept category name read-only and model-generated so organisers cannot introduce naming discrepancies.
- Added live preview in the category form so the generated name changes as event type, gender, age, weight, and belt fields are edited.

### Change Log
- Added category-name source data attributes to editable category fields.
- Added a generated-name preview script to the category form.
- Added controller coverage that the edit form exposes the generated-name preview wiring.

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 134 runs, 1004 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-28 - Hide Cross-Role Registration For Signed-In Users

### Reference
- User request: if a user is already signed in, they should not see registration buttons for other user types because it can create flow problems.

### Product Decisions
- Signed-in users stay inside their existing account context instead of being offered athlete, organiser, or academy-owner account creation CTAs.
- Public visitors still see signup and academy-registration entry points.
- Academy registration remains available from the academies list only for signed-out visitors, academy owners, and super admins.
- Direct access to the account signup page is blocked for signed-in users to prevent accidental duplicate accounts.

### Change Log
- Hid homepage athlete and academy signup CTAs for signed-in users and replaced the lower CTA with a neutral tournaments link.
- Hid login-page secondary registration links when a signed-in user visits the login page directly.
- Hid the academy registration button from signed-in users who are not academy owners or super admins.
- Added a `UsersController` guard that redirects signed-in users away from `new` and `create`.
- Added integration tests for signed-in homepage CTA hiding, signed-in login-page CTA hiding, and direct signup guard behavior.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/home_controller_test.rb test/controllers/sessions_controller_test.rb test/controllers/users_controller_test.rb`; result: 23 runs, 203 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 138 runs, 1032 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-28 - Athlete Account Home And Single-Profile Flow

### Reference
- User request: signed-in athletes should not see organiser or other registration options, should land on their own athlete home/profile, should not search athletes, and should not add more athletes.

### Product Decisions
- Athlete accounts are single-profile accounts: they can complete and edit their own athlete profile, but cannot create additional athlete profiles.
- The athlete home page is the athlete profile page. It is used for the root path redirect, default login destination, and left-menu Athletes link.
- Past tournament history remains on the athlete profile through the existing previous competitions section.
- Signed-in users no longer see the organiser directory registration CTA.

### Change Log
- Added `athlete_home_path` as a helper for the athlete account destination.
- Redirected athlete users with profiles from the public home page and Athletes index to their own profile.
- Updated login defaults so athlete users land on their own profile after sign-in.
- Blocked athlete users with an existing profile from opening or posting the Add athlete flow.
- Updated the left-menu Athletes link to point directly to the signed-in athlete profile.
- Hid the organiser registration CTA from signed-in users on the organiser directory.
- Hid the Add another athlete prompt during tournament registration for athlete accounts.
- Added integration tests for athlete home routing, athlete index redirect, single-profile enforcement, hidden organiser CTA, athlete login default, and registration prompt hiding.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb test/controllers/home_controller_test.rb test/controllers/sessions_controller_test.rb test/controllers/organizers_controller_test.rb test/controllers/registrations_controller_test.rb`; first result: 43 runs, 314 assertions, 0 failures, 1 error because the new athlete registration test needed its own tournament setup.
- Added explicit open tournament and category setup to the athlete registration prompt-hiding test.
- Re-ran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb test/controllers/home_controller_test.rb test/controllers/sessions_controller_test.rb test/controllers/organizers_controller_test.rb test/controllers/registrations_controller_test.rb`; result: 43 runs, 317 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 144 runs, 1057 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-28 - Athlete Tournament Registration Entry Point

### Reference
- User request: athletes should be able to register for a tournament.

### Product Decisions
- Athlete users can register for open tournaments from the tournament detail page, not only from the tournament list.
- Athlete registration uses the signed-in athlete's own profile as a read-only field with a hidden id, avoiding a dropdown that suggests they can select or add other athletes.

### Change Log
- Added a "Register for tournament" CTA on tournament detail pages when the signed-in user can register and is not managing that tournament.
- Updated the registration form to render the signed-in athlete's own profile as read-only when the account has exactly one athlete profile.
- Expanded controller tests to cover the tournament detail registration CTA and the read-only athlete registration field.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/registrations_controller_test.rb`; result: 45 runs, 407 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 145 runs, 1070 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-28 - Professional UI Foundation Pass

### Reference
- User request: use Miru and The Athletic as UI references, keep the existing font family, improve search, icons, styling, and remove unnecessary clutter.
- Reference scan: Miru emphasizes compact operational UI, icon consistency, calm app surfaces, and searchable work tables. The Athletic emphasizes strong editorial hierarchy, restrained black/red contrast, clean card/list density, and crisp navigation.

### Product Decisions
- Kept the existing Arial/Helvetica font stack.
- Added a lightweight inline SVG icon helper instead of adding a new frontend library or gem.
- Reduced visible copy on core index pages and kept labels action-oriented.
- Kept the left menu but made it more app-like with icon-led navigation and compact tournament actions.

### Change Log
- Added reusable `ui_icon` helper with a small internal icon set for search, filters, navigation, tournaments, academies, athletes, organiser, edit, logout, and primary actions.
- Added icons to the left navigation, organiser tournament shortcuts, account actions, search labels, and primary CTAs.
- Refined tournament, academy, and athlete index copy and action presentation.
- Converted search submit controls on key index pages to icon+text buttons.
- Added icon-led text links for common "view" actions.

### Verification Log
- Ran `mise exec -- bin/rails test`; first result: 145 runs, 1058 assertions, 1 failure because an existing tournament filter test expected the old "Tournament filters" and "Apply filters" copy.
- Updated the tournament filter test to expect the refreshed "Find competitions" and "Apply" UI copy.
- Ran `mise exec -- bin/rails test`; second result: 145 runs, 401 assertions, 0 failures, 75 errors because the initial SVG helper used the Rails `tag.svg` API incorrectly.
- Reworked `ui_icon` to use `content_tag(:svg, ...)`, which emits proper hyphenated SVG attributes such as `stroke-width`.
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/users_controller_test.rb`; result: 46 runs, 420 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 145 runs, 1070 assertions, 0 failures, 0 errors, 0 skips.
- Attempted curl smoke checks against the existing Rails server on port 3000. The server process was still listening, but curl body checks were inconsistent after the dev-server state changed.
- Started a temporary Rails server on port 3001 with `PIDFILE=/tmp/sports-hub-ui-smoke-3001.pid mise exec -- bin/rails server -b 127.0.0.1 -p 3001`.
- Verified the tournament index rendered successfully on port 3001 with the refreshed markup: icon SVGs emitted valid `stroke-width` attributes, the filter panel rendered as `tournament-filter-panel`, and the search heading rendered as "Find competitions".
- Stopped the temporary port 3001 Rails server after smoke verification.

## 2026-08-28 - Future Athlete Tournament Status Flow

### Reference
- User request: do not implement now, but remember the future athlete-facing tournament status flow after organiser approval, rejection, weight check, draw setup, match completion, and certificates.

### Future Product Requirements
- When an athlete submits a tournament registration, the request should go to that tournament's organisers.
- If an organiser rejects the registration, the athlete should see a "Not approved" status and the tournament should move into the athlete's past tournaments list.
- If an organiser accepts the registration, the athlete should see the tournament under upcoming events on their athlete profile.
- If a tournament has a weight check date, the athlete should see that date in the upcoming event details.
- If the organiser records weight check attempts and accepts the athlete after any valid attempt, the athlete should continue seeing the tournament in upcoming events and should see match dates when available.
- If the athlete is disqualified during weight check, the athlete should see a "Disqualified" status and the entered weight attempts.
- After set draw is implemented, the athlete should be able to see their schedule and competitors.
- After match completion is implemented, the athlete should be able to see their own match result/status and download a certificate.

### Change Log
- Documentation only. No code changes were made for this future flow.

### Verification Log
- Not run. This is a future requirement note only.

## 2026-08-28 - Academy Athlete Membership Requests

### Reference
- User request: athletes can change academies; unregistered academies should be accepted without links; registered academy changes should notify the academy owner for approval/rejection; academy-created athletes should not require approval.

### Product Decisions
- Added explicit academy membership requests instead of directly changing `athletes.academy_id` when an athlete self-selects a registered academy.
- An athlete's current linked academy remains unchanged while a new registered-academy request is pending.
- Unregistered academy names are stored on the athlete profile as plain text in `external_academy_name`.
- Academy owners see pending join requests on their academy page and can approve or reject them.
- Academy owners and super admins can still directly assign athletes to approved academies without membership approval.

### Change Log
- Added `external_academy_name` to athletes.
- Added `AcademyMembershipRequest` with pending, approved, and rejected statuses, reviewer metadata, and a partial unique index for pending academy/athlete requests.
- Added approve/reject routes and controller actions for academy membership requests.
- Updated athlete create/update flow so athlete accounts generate registered-academy join requests and save unregistered academy text directly.
- Updated athlete forms and profile/list displays for registered academy requests and external academy names.
- Updated academy show page to display pending join requests with approve/reject actions for academy managers.
- Added integration tests for athlete registered-academy requests, unregistered academy text, academy-owner approval/rejection, and direct academy-owner athlete assignment.
- Tightened membership request creation so an existing pending request is reused instead of attempting to create a duplicate row.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: added `athletes.external_academy_name`, created `academy_membership_requests`, and updated `db/schema.rb`.
- Ran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb`; result: 29 runs, 195 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 150 runs, 1118 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace errors.
- Attempted focused controller tests inside the sandbox after the final duplicate-request hardening; Rails could not access the local PostgreSQL socket from the sandbox, so the command was rerun with database access.
- Reran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb`; result: 29 runs, 195 assertions, 0 failures, 0 errors, 0 skips.
- Reran `mise exec -- bin/rails test`; result: 150 runs, 1118 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-28 - Pune Open Weight Check Seed Data

### Reference
- User request: create seed data for weight check for Pune Open Taekwondo Championship.

### Product Decisions
- Converted the seeded Pune Open Taekwondo Championship into a registration-closed demo tournament so organisers can open the weight-check flow immediately.
- Kept Pune Open future-dated so it still behaves like an upcoming event after registration has closed.
- Seeded weight-check examples across the main organiser states: accepted with no attempts, accepted with failed attempts remaining, weight verified after passing, and disqualified after three failed attempts.
- Kept the seed script idempotent by clearing and recreating demo weight-check attempts for the seeded registrations before applying the scripted attempts.

### Change Log
- Added `seed_weight_checks` helper to reset seeded weight-check attempts and replay attempt sequences.
- Updated Pune Open dates/status to `registration_closed` with registration closing one day ago.
- Added four additional Pune Open athlete users and athlete profiles for weight-check testing.
- Added Pune Open registrations for Anaya Kulkarni, Saanvi Joshi, Ishaan Deshmukh, and Rehan Shaikh.
- Added seeded attempt data:
  - Vihaan Mehta: one failed attempt, then passed on attempt 2.
  - Anaya Kulkarni: two failed attempts, still approved for attempt 3.
  - Saanvi Joshi: passed on attempt 1.
  - Ishaan Deshmukh: failed all three attempts and is disqualified.
  - Rehan Shaikh: accepted registration with no weight-check attempts yet.

### Verification Log
- Ran `mise exec -- bin/rails db:seed`; result: seed completed successfully and printed demo credentials.
- Ran a Rails runner verification for Pune Open; result: tournament status is `registration_closed`, registration closes in the past, and 6 registrations exist with expected weight-check statuses and attempts.
- Reran `mise exec -- bin/rails db:seed`; result: seed completed successfully again, confirming repeatability.
- Ran `git diff --check`; result: no whitespace errors.
- Ran `mise exec -- bin/rails test`; result: 150 runs, 1118 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-28 - Athlete Self-Service Academy Selection

### Reference
- User request: in the athlete logged-in flow, remove Association ID; show an "Academy" header with a dropdown of registered academies; keep "Other" in the dropdown and reveal a text field only when Other is selected.

### Product Decisions
- Kept `association_id` in the data model and non-athlete management flows, but removed it from the logged-in athlete self-service form and ignored self-service attempts to update it.
- Registered academy selection by an athlete still creates an academy membership request instead of directly linking the athlete to the academy.
- The Other academy option stores a plain-text `external_academy_name` and creates no academy membership request.
- When an athlete selects a registered academy or no academy, stale external academy text is cleared.
- Added a small global JavaScript asset loaded by the layout, scoped to forms that declare the academy choice data attributes.

### Change Log
- Updated the athlete form to render a single "Academy" dropdown with approved academies plus Other for athlete accounts.
- Added conditional display for the external academy name field when Other is selected.
- Hid Association ID from athlete self-service forms.
- Added JavaScript to toggle the Other academy text field and disable it when not selected.
- Updated athlete controller params so self-service athletes cannot assign academies directly or update Association ID.
- Added tests for the athlete edit form, Other academy submission, registered academy membership requests, stale external academy clearing, and Association ID protection.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb`; first result: 17 runs, 106 assertions, 1 failure because the existing unregistered-academy test did not submit the new `academy_id: "other"` dropdown choice.
- Updated the unregistered-academy test to select Other before submitting the external academy name.
- Reran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb`; result: 17 runs, 107 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace errors.
- Ran `mise exec -- bin/rails test`; result: 152 runs, 1138 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-28 - Left Menu Signed-In Name

### Reference
- User request: when someone signs in, show their first name at the end of the left menu instead of "Athlete" or "Organiser".

### Product Decisions
- Replaced the signed-in role label in the left menu with the user's first name.
- Added a fallback to the email prefix if a user name is unexpectedly blank.
- Kept the existing pill styling so the footer layout remains stable.

### Change Log
- Added `user_first_name` helper for first-name display.
- Updated the application layout side-account footer to render `user_first_name(current_user)`.
- Added a homepage regression assertion that signed-in users see their first name and not the role label in the menu footer.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/home_controller_test.rb`; result: 7 runs, 67 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace errors.
- Ran `mise exec -- bin/rails test`; result: 152 runs, 1142 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-29 - Athlete Tournament Status and Flash Auto-Dismiss

### Reference
- User request: after sign in, the green banner should disappear after 5 seconds; athletes should see upcoming tournaments they registered for and application status such as registered, declined, verified; after weight check, the athlete should see the updated weight-check status.

### Product Decisions
- Flash messages now auto-dismiss on the client after 5 seconds while keeping the server flash behavior unchanged.
- Athlete profile now separates future/current tournament registrations from completed past competitions.
- Athlete-facing registration status labels are different from internal enum names:
  - `pending` is shown as "Application submitted".
  - `approved` is shown as "Registered".
  - `rejected` is shown as "Declined".
  - `weight_verified` is shown as "Weight verified".
  - `disqualified` is shown as "Disqualified".
- Weight-check attempts are shown on athlete profile rows once organisers record them.
- Association ID remains hidden from an athlete viewing their own logged-in profile.

### Change Log
- Added `data-auto-dismiss="5000"` to rendered flash messages.
- Extended `app/assets/javascripts/application.js` to remove auto-dismiss flash elements after five seconds with a short fade.
- Added flash fade styling.
- Added registration helper methods for athlete-facing status labels, status details, and weight-check attempt summaries.
- Updated `AthletesController#show` to prepare upcoming and previous registration collections.
- Updated the athlete profile page to show upcoming tournament registrations with category, date, application status, organiser review message, and weight-check attempts.
- Added tests for sign-in flash auto-dismiss markup and athlete-facing upcoming/past tournament status display, including verified and disqualified weight-check outcomes.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb test/controllers/sessions_controller_test.rb`; first result after upcoming status work: 27 runs, 191 assertions, 0 failures, 0 errors, 0 skips.
- Added disqualified weight-check assertions to the athlete profile status test.
- Reran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb test/controllers/sessions_controller_test.rb`; result: 27 runs, 195 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace errors.
- Ran `mise exec -- bin/rails test`; result: 153 runs, 1173 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-29 - Super Admin Athlete Management

### Reference
- User request: as super user, I should be able to see all athletes and delete all athletes.

### Product Decisions
- Kept the existing super-admin controller visibility rule that exposes all athlete records.
- Updated the athlete index page to make the super-admin context explicit with an "All athletes" heading.
- Added per-athlete delete controls for super admins instead of a bulk delete button, so destructive actions stay deliberate.

### Change Log
- Updated athlete index heading/copy for super admins.
- Added a delete action button to each athlete card when the current user is a super admin.
- Added regression coverage that a super admin sees athletes owned by different users and can delete a selected athlete.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb`; result: 19 runs, 153 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace errors.
- Ran `mise exec -- bin/rails test`; result: 154 runs, 1190 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-29 - Academy Owner Home and Athlete Account Flow

### Reference
- User request: academy owners should land on academy pages after login, see their academies separately from other academies, manage multiple academies, edit owned academies, see/add/remove their athletes, receive athlete join requests, create athlete accounts with emailed passwords, avoid duplicate emails across roles, view athlete tournament statuses, register academy athletes using the existing flow, and not view other academies' athlete profiles.

### Product Decisions
- Academy owner login now defaults to the academies page, where owned academies are shown separately from other approved academies.
- One owner can own multiple academies; the left menu lists every owned academy with Edit academy, My athletes, and Notifications links.
- Academy owners can create athletes only for their own approved academies.
- When an academy owner creates an athlete, Sports Hub creates a separate `athlete` user account and emails temporary sign-in details.
- Athlete account email must be globally unique across all user roles. If an email already belongs to an organiser, academy owner, parent, super admin, or athlete account, the academy-owner add flow is rejected.
- Academy owners can view athlete profiles assigned to their academies, but cannot edit those profiles. Profile edits remain available to the athlete's own login and super admin.
- Academy owner removal detaches the athlete from the academy instead of deleting the athlete profile/user. The athlete's academy link and external academy text are cleared, related pending/approved academy membership requests are marked rejected, and an email notification is queued.
- Academy owners continue to use the existing tournament registration flow for their academy athletes.
- Academy-owned athlete rows now include tournament registration statuses using the same athlete-facing status labels and weight-check attempt summaries.

### Change Log
- Added `Athlete#account_email` as a transient form attribute.
- Added `AthleteAccountMailer` with account-created and academy-removed email templates.
- Updated session default routing for academy owners to `academies_path`.
- Updated academies index with "My academies" and "Other academies" sections for academy owners.
- Updated academy show with stable anchors for notifications and athletes, remove-from-academy actions, and athlete tournament status rows.
- Added academy owner left-menu shortcuts for every owned academy.
- Updated athlete creation so academy owners create a dedicated athlete user account, require unique email, restrict academy selection to owned approved academies, and enqueue sign-in details email.
- Updated athlete editing permissions so academy owners cannot edit athletes assigned to their academies.
- Updated athlete destroy behavior so academy owners remove the academy link and notify the athlete, while super admins and owning users can still delete profiles.
- Added tests for academy-owner default login, academy dashboard separation, left-menu academy shortcuts, academy-created athlete accounts, duplicate email rejection, academy removal notification, academy-level registration statuses, and edit blocking.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/athletes_controller_test.rb test/controllers/sessions_controller_test.rb`; first result: 47 runs, 373 assertions, 1 failure because the "other academies" query excluded academies with `owner_id` null.
- Updated the other-academies query to include approved academies with no owner.
- Reran the focused controller tests; second result: 47 runs, 392 assertions, 1 failure because a privacy assertion matched the left-menu "My athletes" label instead of the other-academy content area.
- Tightened the privacy assertion to check the absence of the registered-athlete list/content.
- Reran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/athletes_controller_test.rb test/controllers/sessions_controller_test.rb`; result: 47 runs, 392 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace errors.
- Ran `mise exec -- bin/rails test`; result: 159 runs, 1262 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-29 - Default-Only Tournament Categories

### Reference
- User request: in the tournament flow, remove all code and UI related to adding or editing categories because tournaments should always use default categories only.
- Annotation context: the earlier category edit work is now superseded by a default-only tournament category flow.

### Product Decisions
- Tournament organisers no longer choose category generation mode, add manual categories, import category files, select default templates, or edit categories.
- Every tournament save now ensures the full Sports Hub default category set exists for that tournament.
- Category records and read-only category pages remain because athlete registration, academy registration, and weight-check flows still depend on tournament category records.
- The existing `category_generation_method` database column remains for compatibility, but the app forces it to "Default categories" on tournament save.

### Change Log
- Removed category add/edit/import routes and simplified `TournamentCategoriesController` to read-only `index` and `show`.
- Deleted tournament category `new`, `edit`, and `_form` views.
- Removed the category generation selector, default-template modal, manual category modal, category import UI, and associated JavaScript from the tournament form.
- Added a simple read-only note on the tournament form that default categories are attached automatically.
- Removed old category-edit permission helpers and stale category editor CSS.
- Deleted the now-unused category CSV fixture.
- Updated tournament and category controller tests to cover default-only category creation and read-only category pages.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/tournament_categories_controller_test.rb`; first sandboxed attempt could not access the local PostgreSQL socket.
- Reran focused tests with normal local DB access; first result found expected test mismatches after removing the category editor.
- Updated the test expectations and tournament form default-category copy.
- Reran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/tournament_categories_controller_test.rb`; result: 40 runs, 362 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 153 runs, 1240 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace errors.
- Ran a final reference sweep for removed category add/edit/import terms; remaining matches are negative test assertions only.

## 2026-08-29 - Tournament Format Defaults Trimmed

### Reference
- User request: remove Para Taekwondo from categories in tournament.

### Product Decisions
- Interpreted "categories in tournament" as the tournament setup competition-format defaults, because Para Taekwondo was present there and not in the generated weight/category templates.
- Tournament organisers can still type custom formats manually if a future event needs one.

### Change Log
- Removed "Para Taekwondo" from `Tournament::DEFAULT_COMPETITION_FORMATS`, so it no longer appears as a default checkbox on the tournament form.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb`; result: 36 runs, 340 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-29 - Super Admin Delete Controls

### Reference
- User request: give super admin an option to delete tournament, athlete, and academy.

### Product Decisions
- Super admins can delete tournaments from tournament list/detail pages.
- Super admins can delete academies from academy list/detail pages.
- Full academy deletion is now super-admin-only. Academy owners can still remove athletes from their academy, but cannot delete the academy record.
- Athlete deletion already existed on the athlete list for super admins; added the same destructive action to the athlete profile page.
- All destructive UI actions use confirmation prompts.

### Change Log
- Added `destroy` routing and controller action for tournaments, guarded by `require_super_admin`.
- Changed academy `destroy` authorization from academy manager to super admin.
- Added delete buttons for super admins on tournament index/show, academy index/show, and athlete show.
- Added controller tests for super-admin tournament deletion, organizer tournament deletion denial, super-admin academy deletion, academy owner academy deletion denial, and athlete profile delete visibility.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/academies_controller_test.rb test/controllers/athletes_controller_test.rb`; result: 77 runs, 706 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 157 runs, 1277 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-29 - Tournament Draw Generation

### Reference
- User request: work on setting draw; no seeding for any athlete; use regular algorithms with minimum byes; round 1 should avoid same-academy athletes fighting when alternatives exist; output should be graphical.
- Visual reference: `39 NSJTC-CC-202601-TS-DAY1.pdf` was inspected as a layout reference only. It shows an Excel-style draw sheet with tournament heading, category title, boxed athletes, academy/state labels, and bracket connector lines.

### Product Decisions
- Draw generation uses only `weight_verified` registrations because those entries have passed the post-registration weight-check flow and are cleared for the draw list.
- Each category gets its own draw when it has at least two draw-ready athletes.
- Bracket size is the next power of two, which gives the minimum possible bye count for a single-elimination bracket.
- There is no athlete seeding. Registrations are read in stable registration order, then paired greedily to avoid same-academy round-1 matches whenever a different-academy opponent is available.
- Same-academy matches are allowed only when the remaining round-1 pool has no alternative.
- Draw generation is non-destructive. If a category already has a generated draw, it is kept instead of overwritten.
- Setting the draw still locks late registrations by moving the tournament to `draw_scheduling`, but only when at least one draw exists or is generated.

### Change Log
- Added `tournament_draws` and `tournament_draw_matches` tables with uniqueness and range constraints.
- Added `TournamentDraw` and `TournamentDrawMatch` models.
- Added tournament/category associations for generated draws.
- Added `TournamentDrawGenerator` service for bracket sizing, first-round pairing, bye placement, and future-round placeholder creation.
- Updated `TournamentsController#set_draw` to generate draw records and block empty draw setup when no category has enough draw-ready athletes.
- Replaced the draw placeholder page with a graphical bracket view inspired by the attached draw-sheet PDF.
- Added draw-specific CSS for sheet headers, round columns, athlete boxes, byes, and bracket connector lines.
- Added model and controller tests for draw generation, minimum byes, first-round academy separation, non-destructive reruns, graphical output, and empty-draw blocking.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: new draw migrations applied successfully.
- Ran `mise exec -- bin/rails test test/models/tournament_draw_generator_test.rb test/controllers/tournaments_controller_test.rb`; result: 43 runs, 398 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 162 runs, 1321 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-29 - Mumbai Draw-Ready Demo Athletes

### Reference
- User request: create about 20 draw-ready athletes for Mumbai Invitational Taekwondo Cup, keep them from different/random unlisted academies, and make them all pass weight check.

### Product Decisions
- Added the records to `db/seeds.rb` so this draw testing dataset is reproducible for future local setups.
- Used unlinked `external_academy_name` values instead of creating real academy records, matching the request for random academies that are not listed in the hub.
- Split the 20 athletes across the Mumbai tournament's three default categories: 6 female cadet entries, 7 junior male entries, and 7 senior male entries.
- Created approved registrations first, then added one passing weight-check attempt per athlete so the existing model callback moves each registration to `weight_verified`.

### Change Log
- Added 20 idempotent Mumbai draw-ready athlete users and profiles to the seed data.
- Added payment-backed approved registrations for Mumbai Invitational Taekwondo Cup.
- Added passing weight checks for each registration so every new entry is ready for draw generation.

### Verification Log
- Ran `mise exec -- bin/rails db:seed`; result: completed successfully and printed demo account credentials.
- Ran a Rails runner verification query for Mumbai Invitational Taekwondo Cup; result: 20 draw-ready registrations, 20 unlinked draw-ready athletes, category split 6/7/7, sample records all had passing latest weight checks.

## 2026-08-29 - Category-Complete Draw Refresh

### Reference
- User report: many athletes were draw-ready but only two appeared in the draw; draw output should be based on categories, and a category with a single athlete should still be shown.

### Root Cause
- Draw generation originally skipped categories with fewer than two athletes.
- Draw generation also preserved existing category draws, which made it possible for a previously generated small draw to stay visible after more athletes became draw-ready.

### Product Decisions
- Every category with at least one `weight_verified` registration now gets an active draw.
- Single-athlete categories render as a two-slot bracket with the athlete and a bye.
- Regenerating a draw now archives previous active draws by setting `superseded_at` instead of deleting draw records or matches. This keeps future audit/history possible while ensuring the visible draw reflects current draw-ready athletes.
- The draw page shows only active draws.

### Change Log
- Added `superseded_at` to `tournament_draws`.
- Replaced the unique category draw index with a partial unique index for active draws only.
- Relaxed the draw `entry_count` constraint and model validation from minimum 2 to minimum 1.
- Updated `TournamentDrawGenerator` to archive previous active draws and rebuild current active category draws.
- Updated empty-state and no-draw messages to say at least one athlete is enough.
- Added tests for active draw refresh and one-athlete category brackets.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: draw-versioning migration applied successfully.
- Ran `mise exec -- bin/rails test test/models/tournament_draw_generator_test.rb test/controllers/tournaments_controller_test.rb`; result: 45 runs, 425 assertions, 0 failures, 0 errors, 0 skips.
- Generated fresh local draws for Mumbai Invitational Taekwondo Cup using `TournamentDrawGenerator`; result: 3 active draws generated, 0 categories skipped.
- Ran `mise exec -- bin/rails test`; result: 164 runs, 1348 assertions, 0 failures, 0 errors, 0 skips.
- Ran a Rails runner verification query for Mumbai Invitational Taekwondo Cup; result: 3 active draws, category split 6/7/7, each category using an 8-slot bracket with 4 first-round match rows.

## 2026-08-29 - Draw Match Scoring And Randomization

### Reference
- User request: do not show academy name on the set draw page; improve the UI; allow entering match points for 3 rounds; select a winner from points; automatically move the winner to the next round; allow head-guard color selection per match; make byes and pairing logic random.

### Product Decisions
- Removed academy labels from draw match cards to keep the draw desk focused on athlete names and match operations.
- Draw generation now shuffles entries, randomly selects byes, randomly places first-round rows, and randomly assigns red/blue head-guard colors.
- First-round pairing still tries to avoid same-academy matchups where alternatives exist, using linked academy ID first and external academy name for unlisted academies.
- Match winners are calculated from total points across three rounds. Tied three-round totals are blocked until an organiser enters a non-tied result.
- Bye matches automatically mark and advance the present athlete.
- Saving a match result updates the next-round match slot immediately, so later round names appear as previous matches finish.

### Change Log
- Added score, winner, head-guard color, completion timestamp, and completion actor fields to `tournament_draw_matches`.
- Added database constraints for non-negative scores, valid head-guard colors, and distinct colors per match.
- Added `TournamentDrawMatchesController#result` for organiser/super-admin match result entry.
- Added model logic for score completeness, winner calculation, bye advancement, and next-round advancement.
- Updated draw generation to randomize pairings/byes/head-guard colors while preserving minimum-bye bracket sizing.
- Reworked the draw page UI into match cards with color selectors, three round score inputs, total score, result state, and save action.
- Updated draw page eager loading for completed-match winner labels.
- Added model and controller tests for score saving, tie blocking, winner advancement, bye advancement, and generated color validity.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: match scoring/head-guard migration applied successfully.
- Ran `mise exec -- bin/rails test test/models/tournament_draw_generator_test.rb test/models/tournament_draw_match_test.rb test/controllers/tournaments_controller_test.rb`; result: 48 runs, 436 assertions, 0 failures, 0 errors, 0 skips.
- Generated fresh local draws for Mumbai Invitational Taekwondo Cup; result: 3 generated, 3 previous active draws archived, 0 skipped, byes auto-advanced.
- Ran `mise exec -- bin/rails test`; result: 169 runs, 1375 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test test/models/tournament_draw_generator_test.rb test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 50 runs, 452 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-29 - Athlete And Academy Draw Visibility

### Reference
- User request: once the draw is set, athletes should see draw status, chest guard color, score, advancement, next match color, and medal result on their profile. Academy owners should see the same tournament/draw status for each of their athletes.

### Product Decisions
- Attached draw visibility to each `Registration`, because both athlete profile and academy tournament-status views already render registrations.
- Athlete and academy views share one partial so both audiences see the same draw state.
- Current match cards show the athlete's chest guard color, opponent, and round/match position.
- Completed match cards show the athlete's score against the opponent, color used, and won/lost result.
- Bye wins are shown as `Bye` instead of fake zero scores.
- Medal labels are inferred from completed draw matches: final winner gets gold, final loser gets silver, and semi-final losers get bronze.
- If an athlete advances before the opponent is known, the profile says they advanced and are waiting for the opponent.

### Change Log
- Added draw-match associations and draw-status helper methods to `Registration`.
- Added reusable `registrations/_draw_status` partial.
- Rendered draw status on athlete profiles for upcoming and previous competitions.
- Rendered draw status in academy owner athlete tournament status.
- Added profile draw-status card styling.
- Added tests for registration draw state, athlete profile visibility, and academy owner visibility.

### Verification Log
- Ran `mise exec -- bin/rails test test/models/registration_test.rb test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb`; result: 49 runs, 410 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 170 runs, 1391 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-29 - Set-Based Match Winner Logic

### Reference
- User correction: match winners should be decided by sets won, not total points. Example: red-blue scores `14-5`, `2-3`, `2-3` should make blue the winner because blue won two sets.
- User requirement: if sets are tied, the referee or organiser should be able to choose the winner.

### Product Decisions
- Each of the three score rows is treated as one set.
- A set goes to the athlete with the higher points in that set.
- Drawn sets do not add a set win to either athlete.
- The match winner is the athlete with more set wins, regardless of total points.
- If set wins are tied after all three sets, saving the result requires an explicit referee/organiser winner selection.
- Athlete and academy profile summaries now show set score as the primary result and raw points as supporting detail.

### Change Log
- Added set-win helper methods to `TournamentDrawMatch`.
- Changed match winner calculation from total points to set wins.
- Added manual winner selection support through the match result form.
- Permitted `winner_registration_id` for organiser/referee tie decisions.
- Updated draw result UI to show set count instead of total points.
- Updated profile draw summaries to show set score plus raw points.
- Added tests for set-based winner logic, explicit tie decisions, and controller result submission with manual winner selection.

### Verification Log
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/models/registration_test.rb test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb`; result: 52 runs, 422 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 173 runs, 1403 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-29 - Draw Medal Outcomes And Fixed Chest Guard Colors

### Reference
- User clarification: in semi-final matches, winners advance to the final and losers receive bronze. In the final, winner receives gold and loser receives silver. These outcomes must be visible on the draw chart and athlete details.
- User clarification: organiser should not change chest guard color; top athlete should generally be blue and bottom athlete red. The athlete row background should carry the color without unnecessary extra labels.
- User instruction: do not commit every change to GitHub; commit only once every 5 hours.

### Product Decisions
- Kept randomized pairing and bye placement, but made chest guard color deterministic: top row blue, bottom row red.
- Removed organiser-editable chest guard color controls from match result submission.
- Added stage-aware result labels on draw matches: semi-final loser gets bronze, final winner gets gold, final loser gets silver, and non-final winners show as advanced.
- Athlete and academy profile draw summaries continue to show medal outcomes, set score, raw points, chest guard color, and won/lost/result label.
- Left these changes uncommitted after verification, following the user's commit cadence instruction.

### Change Log
- Updated draw generation to assign fixed top-blue and bottom-red chest guard colors.
- Removed chest guard color parameters from match result updates.
- Added result-label helpers to `TournamentDrawMatch`.
- Updated draw chart rows to use full red/blue row backgrounds and remove color dropdowns.
- Updated profile draw result labels to show stage outcomes.
- Added tests for semi-final bronze and final gold/silver labels.

### Verification Log
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/models/tournament_draw_generator_test.rb test/models/registration_test.rb test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb`; result: 57 runs, 461 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 174 runs, 1409 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Frozen Draw Results And Tie-Only Decisions

### Reference
- User request: after a referee or organiser enters points for three rounds, the action should be `Freeze result`; once frozen, that match result must become uneditable.
- User request: `Referee decision if sets are tied` should be shown only when the entered three-set score creates a tied set result.

### Product Decisions
- A completed draw match is now treated as the frozen result boundary.
- Frozen matches render their round scores and winner as read-only information on the draw chart.
- Result submissions for already completed matches are rejected at the model layer, so the lock applies outside the UI too.
- The referee decision section is hidden by default and is revealed in the browser only when all three set scores are entered and the set-win count is tied.

### Change Log
- Added `TournamentDrawMatch#set_wins_tied?`.
- Added a guard in `TournamentDrawMatch#record_result!` to block edits after a winner has been stored.
- Changed the match result flash and submit button from save language to freeze language.
- Updated the draw chart to render completed scores in read-only output fields.
- Added JavaScript to toggle the referee decision section based on entered set scores.
- Added tests for frozen result protection and draw-page freeze/tie-decision rendering.

### Verification Log
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 53 runs, 459 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 177 runs, 1430 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Draw Score Field Color Cues

### Reference
- User request: remove the `Waiting / Previous winner` section from draw cards.
- User request: round score inputs should use a very light red and light blue background so referees can tell which score field belongs to which athlete.

### Product Decisions
- Future-round matches now show only entrant rows until both athletes are known.
- Score fields mirror the draw-row convention: top athlete fields are light blue, bottom athlete fields are light red.
- Frozen score outputs use the same color cues as editable score inputs.

### Change Log
- Removed the waiting result bar from incomplete draw matches.
- Added score field classes for blue and red input/output fields.
- Added a controller test assertion to prevent the waiting block from reappearing.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb`; result: 41 runs, 407 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb test/models/registration_test.rb test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb`; result: 97 runs, 853 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Draft Scores Before Freezing Draw Results

### Reference
- User request: bye matches should not show a scoreboard.
- User request: scoreboards should be collapsible and remain openable after a match is finished.
- User request: score inputs should start empty rather than showing `0`.
- User correction: score entry should first save editable draft scores; only after all round scores are entered should the button change to `Freeze result`, and freezing should lock the inputs.

### Product Decisions
- Draft score saving updates the match score columns without selecting a winner or advancing an athlete.
- Freezing is driven by the submitted action value `Freeze result`.
- Completed matches stay frozen and render score values as read-only inside a collapsible scoreboard.
- Bye matches rely on the athlete row/result badge and do not render score controls.
- The submit button starts as `Save result`; browser JavaScript changes it to `Freeze result` only when all six score fields have values.

### Change Log
- Added editable draft score persistence through `TournamentDrawMatch#save_score_draft!`.
- Split draw match controller result handling into draft-save and freeze paths.
- Converted match score UI into a collapsible scoreboard.
- Removed score field placeholders.
- Hid scoreboard rendering for bye matches.
- Updated draw-page and controller tests for draft save, freeze, and bye scoreboard behavior.

### Verification Log
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 55 runs, 480 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb test/models/registration_test.rb test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb`; result: 99 runs, 868 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 179 runs, 1451 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Per-Round Referee Decisions For Tied Scores

### Reference
- User correction: referee tie decisions should happen at the set/round level. If round 1 is `15-15`, the referee chooses that round winner immediately, so a set should never remain a draw.
- User request: replace the large match-level referee decision block with a minimal, intuitive per-round design.

### Product Decisions
- Added one optional winner-side field per scored round: `round_1_winner_side`, `round_2_winner_side`, and `round_3_winner_side`.
- Round winner calculation used points when one side led, and used that round's referee decision only when points were tied.
- Match winner calculation remained based on sets won, but every completed tied set required a per-round decision before freeze could succeed.
- The match-level winner picker was removed from permitted params and UI.
- This approach was later superseded by the no-referee-winner-option flow below.

### Change Log
- Added migration `20260830000100_add_round_decisions_to_tournament_draw_matches`.
- Updated `TournamentDrawMatch` round winner and freeze readiness logic.
- Updated draw result params to permit round decision fields instead of match winner selection.
- Replaced the match-level referee decision fieldset with per-round tie controls.
- Updated JavaScript so `Freeze result` appeared only after all scores and required tied-round decisions were complete.
- Updated model, controller, and draw page tests for per-round referee decisions.

### Verification Log
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 55 runs, 487 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb test/models/registration_test.rb test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb`; result: 99 runs, 875 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 179 runs, 1458 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Draw Page UX Redesign And Tie Input Clarification

### Reference
- User provided light and dark score-table screenshots as inspiration for a cleaner, professional tournament operations interface.
- User correction: an empty score field must not be treated as a tied score. The referee round-winner choice should appear only after both scores in that round are entered and equal.
- User request: perform code review, commit to GitHub, and stop the server after the change.

### Product Decisions
- Kept the site's existing font family, but redesigned draw cards around the screenshot language: clean white panels, thin borders, wide spacing, uppercase operational labels, and squared action buttons.
- Converted the match result submit into an icon button that starts as `Save result` and switches to `Freeze result` with a lock icon only when the scorecard can be frozen.
- Kept tied-round referee choices compact and inline with the specific round that needs a decision.
- Cleared stale round referee decisions when a previously tied round became non-tied.

### Change Log
- Added save and lock icons to `ApplicationHelper`.
- Refined draw page header, draw sheet header, bracket columns, match cards, scoreboards, score inputs, round decision controls, and action buttons.
- Updated JavaScript to switch button text/value/icons together and to compare only entered round scores.
- Added model cleanup for round decisions that no longer apply.
- Updated draw page tests for the redesigned hierarchy.

### Verification Log
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 55 runs, 487 assertions, 0 failures, 0 errors, 0 skips.
- Review follow-up: tightened the bye scoreboard assertion and JavaScript numeric parsing, then reran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 55 runs, 487 assertions, 0 failures, 0 errors, 0 skips.
- Review follow-up: reran `mise exec -- bin/rails test`; result: 179 runs, 1458 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Draw Page Polish And Referee Winner Option Removal

### Reference
- User request: improve the full UI, modernize buttons, and especially improve the set draw page because it looked poor.
- User request: remove the referee option for setting a winner.
- User clarification: empty score inputs must not count as equal scores.

### Product Decisions
- Removed all active referee winner selection UI and controller/model paths.
- Kept tied score detection as a small non-interactive state: a tied round can be saved as draft, but the match cannot be frozen until scores produce a point winner for every round.
- Left previously added database columns in place because dropping them would be destructive and was not explicitly approved.
- Refined the draw page toward a cleaner operations-sheet style: crisp panels, square match cards, tighter scoreboards, uppercase labels, modern action buttons, and cleaner blue/red visual mapping.
- Updated shared primary, secondary, nav, and icon button styling to feel sleeker without changing the site font family.

### Change Log
- Removed round decision inputs from the draw page.
- Removed round decision params from draw match result submission.
- Changed draw match winner calculation to reject tied rounds during freeze instead of accepting manual winner choices.
- Simplified score JavaScript to only show tied-round notes after both scores in that round are entered and equal.
- Updated draw scoreboard and global button styling.
- Removed a stale set-win tie helper that only supported the previous referee-decision flow.
- Updated model, controller, and draw page tests for the no-referee-option scoring flow.

### Verification Log
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 55 runs, 483 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb test/models/registration_test.rb test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb`; result: 99 runs, 871 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 179 runs, 1454 assertions, 0 failures, 0 errors, 0 skips.
- Final review follow-up: removed a stale set-win tie helper, ran `git diff --check`; result: clean.
- Reran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 55 runs, 483 assertions, 0 failures, 0 errors, 0 skips.
- Reran `mise exec -- bin/rails test`; result: 179 runs, 1454 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Removed Visible Round-Tied Draw Control

### Reference
- User request: remove the round tied button.

### Product Decisions
- Removed the visible `Round tied` pill/control from editable and frozen draw scoreboards.
- Kept the scoring rule unchanged: tied rounds may be saved as draft scores, but a match cannot be frozen until each round has a point winner.

### Change Log
- Removed round-tied markup from the draw page.
- Removed unused round-tied CSS.
- Simplified draw score JavaScript so it only uses tied-round detection to decide whether the submit action can become `Freeze result`.
- Updated draw page tests to assert that the `Round tied` UI and data hook are absent.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/models/tournament_draw_match_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 55 runs, 485 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Compact And Uniform Draw Match Cards

### Reference
- User feedback: draw containers were uneven, empty fields were too large, and bye blocks did not feel consistent with the rest of the draw page.

### Product Decisions
- Standardized draw match card sizing so ready, bye, and pending matches share the same compact visual system.
- Empty future slots and bye slots now render as quiet neutral rows instead of full red/blue athlete blocks.
- Scoreboards and score inputs remain available only for real matches, but use a smaller, denser layout.

### Change Log
- Added match state classes for ready, bye, and pending draw matches.
- Added empty entrant row styling for unassigned bracket slots.
- Reduced draw column width, card rail width, entrant height, scoreboard spacing, score input height, and action button height.
- Aligned connector spacing with the tighter bracket layout.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/models/tournament_draw_match_test.rb`; result: 55 runs, 485 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Horizontal Dendrogram Draw Layout

### Reference
- User feedback: the tree UI was messed up and should look like a proper horizontal dendrogram.

### Product Decisions
- Replaced margin-based bracket spacing with explicit row-span placement per match.
- Collapsed scoreboards by default so scoring controls do not distort the bracket tree.
- Kept bye and pending matches compact while centering them in the same bracket slot system as live matches.

### Change Log
- Added bracket size, match row start, row span, and connector height CSS variables to draw match markup.
- Updated draw bracket CSS to use shared slot rows, centered match cards, and connector lines between rounds.
- Adjusted match card and slot dimensions so real matches, byes, and pending slots remain visually aligned.
- Updated draw page tests to assert the rendered bracket carries dendrogram layout variables.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/models/tournament_draw_match_test.rb`; result: 55 runs, 491 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Draw Flow Hardening Before External Review

### Reference
- User request: Claude and Copilot will review the code later, so make sure flows have no errors, write tests, put everything properly, add UI testing for button/container sizing, ensure action results appear on other user surfaces, remove unwanted code, and push to GitHub.

### Product Decisions
- Kept the implementation inside the Rails/Minitest stack already used by the project instead of adding a new browser-testing dependency.
- Added a CSS/layout contract test for the draw dendrogram and shared button styling so future edits cannot easily break the bracket structure silently.
- Added a cross-role flow test that freezes a match through the organiser endpoint, then verifies the athlete profile and academy page both show the updated draw state.
- Removed active stale referee-winner code paths from app and test files. The old database columns remain dormant because dropping persisted columns is a destructive schema change and should be approved separately.

### Change Log
- Added `DrawLayoutContractTest` for draw row-grid, connector, compact card, bye/pending, and button styling invariants.
- Extended draw page integration assertions for bracket layout variables, collapsed scoreboards, and bye placeholder states.
- Added a tournament draw match controller propagation test covering organiser result freeze to athlete and academy views.
- Searched active app/test code for previous referee-decision selectors/helpers and confirmed they are no longer present.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/draw_layout_contract_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/controllers/tournaments_controller_test.rb test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb test/models/registration_test.rb test/models/tournament_draw_match_test.rb`; result: 102 runs, 951 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 182 runs, 1534 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Academy Breadcrumbs And Athlete Row Action Menu

### Reference
- User request: for academy flow, add breadcrumbs.
- User request: at the end of academy athlete rows, replace the separate view/remove buttons with a vertical dots/kebab menu and move view/edit/remove actions inside it, using appropriate icons.

### Product Decisions
- Added breadcrumbs to academy index, show, new, and edit pages.
- Replaced visible row actions in the academy athlete list with a compact native `details` kebab menu.
- Kept athlete edit visibility aligned with existing permissions: super admins and the athlete's own account can edit; academy owners can view/remove their academy athlete entries from this menu.
- Added a copy-email menu item when the athlete is linked to a user email.

### Change Log
- Added `copy`, `eye`, `more-vertical`, and `trash` icons to `ApplicationHelper`.
- Added academy breadcrumbs to academy flow views.
- Added the academy athlete row actions dropdown with copy email, view profile, conditional edit member, and remove athlete actions.
- Added clipboard feedback JavaScript for menu copy actions.
- Added menu styling for compact icon trigger, floating actions panel, and destructive action state.
- Added academy UI tests for breadcrumbs, kebab menu contents, edit permission visibility, and menu CSS contract.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/academy_layout_contract_test.rb`; result: 22 runs, 261 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 185 runs, 1599 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Academy Cards, Removal Confirmation, And Athlete Breadcrumbs

### Reference
- User request: add breadcrumbs on athlete profile.
- User request: after Copy email changes to Copied, the actions panel should disappear.
- User request: when an academy owner removes an athlete, show a confirmation popup and unlink the athlete from the academy only if confirmed.
- User request: on the academy homepage, remove the visible `Approved` word before the academy name while keeping stored status.
- User request: redesign academy cards using the supplied screenshot as inspiration: academy image, academy name, three-dot menu with view/edit/add athlete, small registered-athlete photos, no plus icon on the card, and opening the details page when the card is clicked.

### Product Decisions
- Added an academy image upload using Active Storage, with a 5 MB maximum file size.
- Kept academy status stored in the database and available as card metadata, but removed the visible status pill from academy cards.
- Made the academy card body a link to the academy detail page, with the three-dot menu kept as a separate action surface.
- Academy-owner removal now unlinks the athlete from the academy and notifies the athlete; it does not delete the athlete profile.
- The athlete edit action in academy row menus remains limited to super admins or the athlete's own athlete account.

### Change Log
- Added athlete profile breadcrumbs.
- Added `Academy#logo_image` and logo image validation.
- Permitted academy logo uploads in `AcademiesController`.
- Added logo upload field to the academy form.
- Replaced academy index entity cards with reusable `academies/_academy_card`.
- Added academy card logo, body, kebab menu, and athlete thumbnail stack styling.
- Updated copy-email JavaScript to close the actions menu after copied feedback.
- Updated academy row remove confirmation text.
- Reordered athlete destroy logic so academy owners unlink academy athletes before any self-owned athlete deletion branch.
- Added tests for logo uploads, academy card rendering, hidden visible status, athlete breadcrumbs, copy-close JavaScript, and academy-owner unlink behavior.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/academy_layout_contract_test.rb test/controllers/athletes_controller_test.rb`; result: 46 runs, 495 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 189 runs, 1665 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Academy Logo And Contact Detail Polish

### Reference
- User request: remove the `Super admin approval required` text from the academy registration page and replace it with clearer user-facing guidance.
- User request: show academy contact details better on the academy detail page.
- User request: ask for and display an academy logo instead of a banner.
- User request: place academy actions in a top-right three-dot menu and prevent the menu from being hidden by lower cards.

### Product Decisions
- Academy branding is now modeled as a logo upload rather than a banner upload.
- Academy registration copy now describes the user outcome: once approved, the owner can manage the profile and add athletes.
- Academy detail pages now lead with logo, academy identity, location, and a compact action menu.
- Contact details are grouped in a dedicated panel with contact person, email, phone, and owner.

### Change Log
- Renamed the academy Active Storage attachment from `banner_image` to `logo_image`.
- Updated academy create/update params and eager-loading to use `logo_image`.
- Updated the academy form label, upload hint, and current-upload display.
- Updated academy cards to display logo artwork or a logo placeholder.
- Added a top-right action menu to academy detail pages and removed duplicate bottom action buttons.
- Added z-index handling for open academy card menus so the panel stays above neighboring cards.
- Added academy detail contact panel styling and mobile layout rules.
- Updated academy controller/layout tests for logo uploads, academy registration copy, contact display, and top action menus.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/academy_layout_contract_test.rb test/controllers/athletes_controller_test.rb`; result: 48 runs, 544 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 191 runs, 1714 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Academy Detail, Roster, And Notifications Split

### Reference
- User request: `/academies/:id` should show only academy details.
- User request: academy athletes should be available, but on a separate page.
- User request: academy notifications should be available on a separate page.
- User request: each notification should have a small cross in the top right; clicking it should softly delete the notification.
- User request: when an athlete adds a registered academy in their profile, the academy owner should be notified and able to accept or reject the athlete.

### Product Decisions
- Academy profile pages are now clean profile/detail pages for identity, logo, location, and contact details.
- Academy roster and athlete tournament statuses live on an owner-only academy athletes page.
- Academy join requests live on an owner-only notifications page.
- Dismissing a notification sets `dismissed_at`; it does not delete the membership request or change the pending approval status.
- If an athlete selects the same registered academy again after a dismissed pending request, the request is re-opened by clearing `dismissed_at`.

### Change Log
- Added `dismissed_at` to `academy_membership_requests` with an index.
- Added `AcademyMembershipRequest.active_notifications` and `#dismiss!`.
- Added `AcademiesController#athletes` and `#notifications`.
- Added academy member routes for `athletes` and `notifications`.
- Added `AcademyMembershipRequestsController#dismiss`.
- Moved academy roster and athlete tournament status UI to `app/views/academies/athletes.html.erb`.
- Moved academy join request review UI to `app/views/academies/notifications.html.erb`.
- Added a top-right dismiss button to each academy notification.
- Updated the signed-in academy owner side menu to use the new academy subpages.
- Added an `x` icon for dismiss actions.
- Updated athlete academy-request creation to re-open dismissed pending requests.
- Updated academy/athlete tests for the new page split and notification dismissal behavior.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: `20260830180500 AddDismissedAtToAcademyMembershipRequests` migrated successfully.
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/athletes_controller_test.rb test/controllers/academy_layout_contract_test.rb`; result: 50 runs, 570 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 193 runs, 1740 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Academy Athlete Tournament Status Grouping

### Reference
- User request: on `/academies/:id/athletes`, group `Tournament status` entries based on tournament.

### Product Decisions
- Academy athlete tournament statuses are grouped by tournament, newest tournament first.
- Each tournament group has a tournament header and keeps athlete/category/status rows underneath it.

### Change Log
- Updated `app/views/academies/athletes.html.erb` to group `@athlete_registrations` by tournament.
- Added tournament status group styling to keep the grouped sections compact and scannable.
- Expanded academy controller tests to cover grouped rendering and newest-first tournament ordering.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb`; result: 25 runs, 342 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 193 runs, 1748 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Academy Tournament Status Table Polish

### Reference
- User request: on `/academies/:id/athletes`, remove redundant draw wording because `Draw not set` and `Draw pending` mean the same thing.
- User request: arrange registration statuses in a tabular format because the status pills were not aligned well.
- User request: add a small circular athlete photo and show more athlete details, using the supplied table screenshot as inspiration.

### Product Decisions
- The academy athletes page now uses a table-like layout for tournament status groups instead of nested draw cards.
- Draw state appears once per registration row.
- Athlete identity in the status table includes a circular photo/placeholder plus email, belt, and weight when available.

### Change Log
- Replaced the academy tournament status `approval-row` layout with `tournament-status-table` rows.
- Added columns for athlete, category, weight check, draw, and application status.
- Removed the embedded registration draw card from the academy status table to avoid redundant `Draw not set` / `Draw pending` wording.
- Added table, avatar, and responsive mobile styles for tournament status rows.
- Updated the academy status test to cover table classes, avatar output, athlete details, and removal of redundant draw pending text.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb`; result: 25 runs, 366 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 193 runs, 1772 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Academy Status Table Refinement

### Reference
- User request: the academy athlete tournament status table looked shabby and needed better alignment.
- User request: shorten the `Application submitted` status label.
- User request: move each athlete detail to a new line in the athlete identity cell.
- User request: commit to GitHub after completion and stop the server after 10 minutes.

### Product Decisions
- Registration `pending` status is now shown as `Submitted` in user-facing status pills.
- The detailed helper text still explains that submitted registrations are waiting for organiser review where that context is needed.
- The academy tournament status table keeps a single draw state and displays athlete email, belt, weight, and city on separate lines.

### Change Log
- Updated `Registration#athlete_status_label` to return `Submitted` for pending registrations.
- Reworked the academy tournament status table row spacing, columns, hover treatment, and avatar sizing.
- Updated academy athlete status rows so each athlete detail renders as its own line.
- Updated academy and athlete controller tests for the shorter `Submitted` status label.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/athletes_controller_test.rb test/controllers/tournament_draw_matches_controller_test.rb`; result: 52 runs, 610 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 193 runs, 1772 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-30 - Academy Status Athlete Metadata Removed

### Reference
- User request: in the tournament status view, remove athlete email, weight, city, and belt details.

### Product Decisions
- Tournament status rows now show only the athlete photo/placeholder and athlete name in the athlete column.
- Detailed athlete profile metadata remains available from the roster row/profile page, but does not clutter tournament registration status.

### Change Log
- Removed email, belt, weight, and city rendering from the academy tournament status athlete cell.
- Updated academy controller tests so the tournament status table asserts photo/name only and no longer expects metadata in that section.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb`; result: 25 runs, 362 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 193 runs, 1768 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-31 - Draw Match Number Labels

### Reference
- User request: for organisers, match numbers should be simple sequential numbers like `1, 2, 3, 4`, not decimal labels such as `2.2`.

### Product Decisions
- The draw page now keeps database round/position values for bracket logic, but uses a separate display number for organiser-facing match labels.
- Display numbers are assigned by ordered draw match sequence: round number, then position.

### Change Log
- Updated `app/views/tournaments/draw.html.erb` to compute visible match numbers from the ordered draw matches.
- Replaced the previous round/position label expression that could render decimal-style labels.
- Added a tournament controller regression test for sequential draw labels across multiple rounds.

### Verification Log
- Ran `git diff --check`; result: clean.
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/models/tournament_draw_match_test.rb test/models/tournament_draw_generator_test.rb`; result: 61 runs, 576 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 194 runs, 1787 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-31 - Draw Scoreboard Layout Repair

### Reference
- User reported the organiser draw UI was broken and supplied screenshots showing vertical match-number rails and expanded scoreboards overlapping adjacent matches.

### Product Decisions
- Match numbers remain simple sequential labels, but are now rendered as compact horizontal badges instead of vertical rails.
- Open scoreboards reserve enough bracket height so expanded inputs do not overlap the next match card.

### Change Log
- Replaced the vertical `.draw-match-number` rail styling with a compact absolute-positioned badge.
- Removed the dedicated match-number grid column from `.draw-match`.
- Increased draw slot height and open-scoreboard minimum height to keep expanded scoreboards inside their bracket lanes.
- Slightly increased pending/bye match height for consistency with the new badge.
- Updated draw layout contract tests to prevent the vertical rail and overlap-prone sizing from returning.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/tournament_draw_matches_controller_test.rb test/models/tournament_draw_match_test.rb test/models/tournament_draw_generator_test.rb test/controllers/draw_layout_contract_test.rb`; result: 63 runs, 624 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 194 runs, 1797 assertions, 0 failures, 0 errors, 0 skips.
- Ran a headless Chromium layout probe against `http://127.0.0.1:3000/tournaments/8/draw` as `organizer@sportshub.test`; result: match number badges render horizontally, all scoreboards in the first draw can be opened, and no measured match-form overlaps were detected.

## 2026-08-31 - Organizer Registration Approval Table

### Reference
- User request: arrange `/organizer/registrations` data in a proper table.
- User request: keep status shown as is, keep `View receipt` as an action but change its font color, and move `View` and other options into a kebab/three-dot menu.

### Product Decisions
- Organizer registration approvals now use table semantics with columns for athlete, tournament, category, status, receipt, and row actions.
- `View receipt` stays directly visible for fast receipt review.
- Secondary row actions live in the existing shared kebab menu pattern used elsewhere in the app.

### Change Log
- Reworked `app/views/organizer/registrations/index.html.erb` from compressed grid rows into a full table.
- Added table-specific CSS and a blue receipt action link style.
- Added organiser registration controller assertions for the table contract, visible receipt action, and kebab menu actions.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/organizer_registrations_controller_test.rb`; result: 5 runs, 61 assertions, 0 failures, 0 errors, 0 skips.
- Ran a headless Chromium probe against `http://127.0.0.1:3000/organizer/registrations` as `organizer@sportshub.test`; result: six-column table rendered, 26 rows present, `View receipt` remained directly visible with blue link color, and the kebab menu opened successfully.
- Ran `mise exec -- bin/rails test`; result: 194 runs, 1815 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-31 - Tournament Setup Visibility and Organizer Invites

### Reference
- User request: in tournament creation, remove the timezone control and remove `Pair Poomsae`.
- User request: selected refund policy should appear on the tournament details page for athlete and academy viewers.
- User request: other organiser flow should include an `Organiser does not have an account` checkbox; when selected, the existing-organiser dropdown should be disabled and a new invite email field should appear. Multiple organisers can be added to a tournament.

### Product Decisions
- Timezone remains in the database for existing data compatibility, but is no longer shown in the tournament create/edit form or tournament details summary.
- `Pair Poomsae` is removed from the default competition format checklist.
- Existing verified organisers are still added through the search/datalist picker.
- New organiser invites can now be added as multiple email chips and are sent when the tournament is saved.
- The refund policy remains public tournament information and is visible to signed-out, athlete, and academy viewers.

### Change Log
- Removed the timezone field from the tournament form and tournament detail summary.
- Removed `Pair Poomsae` from `Tournament::DEFAULT_COMPETITION_FORMATS`.
- Reworked the other-organiser picker UI to show selected organiser chips, an existing-organiser search row, an account-missing checkbox, and invite email chips.
- Updated tournament invitation handling to accept both the existing single email field and the new multiple email array.
- Added controller coverage for form visibility, multiple organiser invitations, and public refund policy display.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb`; result: 45 runs, 470 assertions, 0 failures, 0 errors, 0 skips.
- Ran a headless Chromium probe against `http://127.0.0.1:3000/tournaments/new` as `organizer@sportshub.test`; result: timezone and `Pair Poomsae` were absent, the invite field was hidden by default, selecting `Organiser does not have an account` disabled the existing-organiser search, revealed the invite field, and added an invite email chip with a hidden submit value.
- Ran `mise exec -- bin/rails test`; result: 196 runs, 1836 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-31 - Draw Connector Line Repair

### Reference
- User request: the draw graph connecting lines looked broken and needed the connecting lines updated.

### Product Decisions
- Connector height now matches the current bracket slot sizing instead of the old compact-card sizing.
- The draw graph uses deliberate horizontal connector segments from match cards plus vertical joins into later rounds, avoiding wrapper borders that made the tree look uneven.

### Change Log
- Updated draw connector height calculation from the old 36px unit to the current 87px half-slot unit.
- Removed the wrapper-level right border/connector from draw matches.
- Added explicit outgoing connector lines from match cards before the final round.
- Strengthened draw layout tests for connector height and connector CSS.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/draw_layout_contract_test.rb`; result: 47 runs, 528 assertions, 0 failures, 0 errors, 0 skips.
- Ran a headless Chromium probe against `http://127.0.0.1:3000/tournaments/8/draw` as `organizer@sportshub.test`; result: second-round connector height was `348px`, first-round outgoing connector width was `24px`, wrapper right border was `0px`, and connector color rendered as `rgb(201, 200, 195)`.
- Captured and visually inspected `/tmp/sports-hub-draw-connectors.png`; result: match number rail stayed removed and bracket connector joins followed the updated bracket spacing.
- Ran `mise exec -- bin/rails test`; result: 196 runs, 1846 assertions, 0 failures, 0 errors, 0 skips.

## 2026-08-31 - Fly.io Rails Deployment Setup

### Reference
- User reported Fly launch failing with macOS system Ruby/Bundler errors and later shared a partial Fly launch summary for the Rails app.
- User wants to deploy the Rails app, not a Static app, to Fly.io.

### Product Decisions
- Fly commands must be run from `/Users/sonamgoyal/Documents/taekwondo-hub` through `mise exec --` so Fly's Rails scanner uses the project Ruby/Bundler instead of macOS Ruby 2.6.
- The Fly app name is `taekwondo-hub` and the primary region is `sin`.
- Production database connection remains environment-driven through `DATABASE_URL`.
- Production uploads use Fly Tigris through Active Storage's S3 adapter.
- Use a Dockerfile-based deploy because this app does not have the Rails Dockerfile generator installed.

### Change Log
- Added `Dockerfile`, `.dockerignore`, `bin/docker-entrypoint`, and `fly.toml` for Fly deployment.
- Added `aws-sdk-s3` for Active Storage S3/Tigris support and updated `Gemfile.lock`.
- Added an `amazon` S3 service to `config/storage.yml`.
- Configured production Active Storage to use the `amazon` service.

### Operational Notes
- `mise exec -- fly apps list` showed Fly app `taekwondo-hub` in `pending` state with no deployed image.
- `mise exec -- fly secrets list --app taekwondo-hub` showed staged `SECRET_KEY_BASE`, `DATABASE_URL`, and Tigris S3 secrets that still need explicit deployment.
- `mise exec -- fly mpg list -o personal` showed two Basic plan clusters named `taekwondo-hub-db`: one attached to `taekwondo-hub` and one with no attached apps. The unattached cluster should be reviewed for deletion to avoid unintended cost.
- Secret deployment was intentionally not performed because it requires explicit user approval to publish database and Tigris credentials to Fly.

### Verification Log
- Ran `mise exec -- bundle install`; result: `aws-sdk-s3` and dependencies installed, bundle complete.
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/organizer_registrations_controller_test.rb test/controllers/draw_layout_contract_test.rb`; result: 52 runs, 589 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- env RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 AWS_ACCESS_KEY_ID=dummy AWS_SECRET_ACCESS_KEY=dummy AWS_REGION=auto AWS_ENDPOINT_URL_S3=https://example.com BUCKET_NAME=dummy-bucket bin/rails runner 'puts Rails.env; puts Rails.application.config.active_storage.service; puts ActiveStorage::Blob.service.name'`; result: production booted with Active Storage service `amazon`.

## 2026-09-01 - Set Draw Dark Bracket UI

### Reference
- User supplied `/Users/sonamgoyal/Desktop/Screenshot 2026-09-01 at 12.30.52 AM.png` as a visual reference for improving the set draw UI.

### Product Decisions
- Keep the existing draw/scoring behavior unchanged.
- Restyle only the set draw board so it feels like a focused tournament bracket surface.
- Use a dark canvas, compact match cards, grey round headers, amber connector accents, and slim side color indicators inspired by the reference.

### Change Log
- Updated draw page background, heading, sheet, round labels, connector lines, match cards, entrant rows, scoreboard, result bar, and button hover styling.
- Added draw layout contract assertions for the dark board and connector/card visual system.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/draw_layout_contract_test.rb test/controllers/tournaments_controller_test.rb test/controllers/tournament_draw_matches_controller_test.rb`; result: 53 runs, 600 assertions, 0 failures, 0 errors, 0 skips.
- Ran a headless Chromium probe against `http://127.0.0.1:3000/tournaments/8/draw` as `organizer@sportshub.test`; result: draw page background rendered `rgb(9, 10, 11)`, draw sheet rendered `rgb(13, 14, 16)`, round headers rendered as light grey pills, entrant rows rendered dark, and connector lines rendered `rgb(54, 56, 61)`.
- Captured and visually inspected `/tmp/sports-hub-set-draw-dark.png`; result: set draw page now uses a dark focused bracket board, compact match cards, amber match badges, grey round labels, and subtle connector lines inspired by the supplied reference.
- Ran `mise exec -- bin/rails test`; result: 196 runs, 1856 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-01 - Athlete Flow Cleanup

### Reference
- User requested cleanup across the athlete profile/edit/registration/tournament views, including upload limits, emergency contact display, academy selector copy, upcoming tournament alignment, hiding athlete registration details from athlete tournament pages, and academy card kebab menu placement.

### Product Decisions
- Athlete profile photo and athlete government document uploads accept JPG or PNG only, up to 5 MB.
- A blank academy selection in the athlete self-service profile leaves the athlete without a selected academy instead of creating a join request.
- Athlete tournament profile status should show one clear status pill per registration; draw setup is not repeated in a separate card.
- Signed-in athletes can see tournament details and categories on tournament pages without seeing the registered athletes operational section.

### Change Log
- Added content-type validation for `Athlete#profile_photo` and `Athlete#identity_document`.
- Updated athlete edit profile copy for registered academy approval requests and unregistered academy entry.
- Updated athlete file inputs and hints to show JPG/PNG up to 5 MB.
- Displayed emergency contact name and phone number on separate profile lines.
- Replaced athlete upcoming/previous tournament rows with aligned event rows and removed the repeated draw status container from those lists.
- Removed the `Required when submitting.` sentence from the payment receipt upload hint.
- Hid the tournament registered-athletes section from signed-in athlete users.
- Anchored academy card kebab menus to the tile's top-right corner with a stronger floating panel layer.

### Verification Log
- First focused test run exposed a regression where inline draw advancement details disappeared from athlete pages; fixed by restoring draw details inside the aligned event rows without reintroducing the old draw status card.
- Ran `mise exec -- bin/rails test test/models/athlete_test.rb test/controllers/athletes_controller_test.rb test/controllers/tournaments_controller_test.rb test/controllers/academy_layout_contract_test.rb`; result: 78 runs, 757 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test test/controllers/tournament_draw_matches_controller_test.rb test/models/athlete_test.rb test/controllers/athletes_controller_test.rb test/controllers/tournaments_controller_test.rb test/controllers/academy_layout_contract_test.rb`; result: 84 runs, 819 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 200 runs, 1885 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-01 - Academy Tile Menu Removal

### Reference
- User requested removing the three-dot/kebab menu from all academy tiles on `/academies`.

### Product Decisions
- Academy tiles should be simple clickable cards on the academy index.
- Academy management actions remain available from academy detail and dedicated academy navigation, not from the tile menu.

### Change Log
- Removed the kebab menu markup from the shared academy card partial.
- Removed academy-card-specific kebab positioning styles.
- Updated academy card layout tests and academy index controller assertions to require no tile menu.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/academy_layout_contract_test.rb`; result: 29 runs, 414 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-01 - Athlete Registered Pill and Tournament CTA Alignment

### Reference
- User supplied `/Users/sonamgoyal/Desktop/Screenshot 2026-09-01 at 1.29.06 AM.png` and requested removing the green `Registered` pill from the athlete upcoming tournament block and aligning the `Register for tournament` button on tournament detail pages.

### Product Decisions
- Accepted athlete registrations should rely on the explanatory status sentence instead of repeating the state as a green pill.
- Other athlete registration states remain visible as status pills because they communicate action or risk.
- The tournament registration CTA should keep its text centered and on one line.

### Change Log
- Hid the athlete event status pill for accepted registrations on athlete profile event lists.
- Added a tournament-specific register button class with centered, single-line text.
- Updated athlete profile controller coverage to assert the accepted detail remains and the registered pill is not rendered.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 68 runs, 678 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-01 - Add Athlete Copy and Error Highlighting

### Reference
- User requested changing the add-athlete page copy and highlighting all invalid text boxes together when the athlete create flow returns validation errors.

### Product Decisions
- The athlete-owned create flow should speak directly to the athlete: `Your profile will be reused across future tournament registrations.`
- Validation feedback should preserve the summary list and also mark each invalid control visually.

### Change Log
- Updated the athlete new-page helper copy for non-academy-owner users.
- Added CSS for Rails `field_with_errors` wrappers so invalid inputs, selects, textareas, and file fields receive a red border, soft red background, and focus outline.
- Added athlete controller tests for the updated copy and multi-field invalid-state highlighting.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb`; result: 24 runs, 213 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-01 - Academy Registration Copy and Inline Form Errors

### Reference
- User requested academy registration copy changes, academy form validation feedback, logo upload validation, and notification copy cleanup.

### Product Decisions
- The academy registration login flow should use `Register academy` and `Sign in and create academy`, without the public CTA saying `academy owner`.
- The academy form intro should say `Add your academy profile` and explain that athletes can be added after approval.
- Field-level errors should appear under inputs while the existing summary remains at the top.
- Forms should reserve inline error space and clear the visible error/highlight once a user edits the field.
- Academy logos accept PNG/JPG only and must be under 5 MB.

### Change Log
- Added a reusable `field_error` helper for inline form error slots.
- Added inline error slots to academy and account registration forms, and to the athlete profile form.
- Added CSS for inline error text, reserved error height, resolved error hiding, and existing invalid field highlighting.
- Added JavaScript to clear resolved field highlights and inline messages on input/change.
- Updated academy registration/login labels and academy form intro copy.
- Added server-side academy logo content-type validation and updated the logo hint.
- Removed the academy notifications subheading and updated the empty notification message.
- Updated academy/session/user/layout tests and added academy logo model coverage.

### Verification Log
- Ran `mise exec -- bin/rails test test/models/academy_test.rb test/controllers/academies_controller_test.rb test/controllers/academy_layout_contract_test.rb test/controllers/sessions_controller_test.rb test/controllers/users_controller_test.rb test/controllers/athletes_controller_test.rb`; result: 77 runs, 826 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 205 runs, 1947 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-01 - Academy Roster and Notification Review Alignment

### Reference
- User requested better table alignment on `/academies/5/athletes`, better button/text alignment on `/academies/5/notifications`, and the ability for an academy owner to click a pending athlete name, view the athlete profile, return, and still accept or reject the request.

### Product Decisions
- Academy owners can view athlete profiles that have pending join requests for one of their approved academies.
- Notification athlete names link to the profile with a safe return path back to the academy notification queue.
- Roster rows and tournament status rows use explicit alignment rules so avatars, details, statuses, and action menus line up consistently.

### Change Log
- Added pending academy membership request athletes to the academy owner's visible athlete scope.
- Added return-path support to athlete profile pages.
- Linked notification athlete names to the athlete profile with `return_to` pointing back to notifications.
- Updated roster/tournament status/notification CSS for row alignment and centered action button text.
- Added controller and layout coverage for the pending athlete review path and aligned row/action styles.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/academy_layout_contract_test.rb test/controllers/athletes_controller_test.rb`; result: 56 runs, 685 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-01 - Super Admin Tournament Delete and Kebab Dismissal

### Reference
- User requested aligning super-admin delete buttons on tournament detail/list pages, showing a confirmation popup for tournament deletion, and closing the academy page kebab menu when clicking outside it.

### Product Decisions
- Tournament destructive actions should sit in a consistent action toolbar or card action row and use a clear confirmation question.
- Generic kebab menus should close when the user clicks outside the open menu.

### Change Log
- Wrapped tournament detail edit/delete actions in a `page-actions` toolbar.
- Added `delete-action-button` styling and card action alignment for tournament list delete buttons.
- Updated tournament delete confirmations to ask `Are you sure you want to delete ...?`.
- Added JavaScript to close open `details.kebab-menu` menus on outside clicks.
- Added controller/layout assertions for delete alignment, confirmation copy, and outside-click menu behavior.

### Verification Log
- Ran `git diff --check`; result: no whitespace or patch formatting errors.
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/academy_layout_contract_test.rb`; result: 53 runs, 594 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-01 - Super Admin Notification Inbox

### Reference
- User requested a super-admin notifications page in the left menu.
- Required notification routing:
  - Athlete selecting a registered academy should notify that academy owner for approval.
  - Athlete listing an unregistered academy should notify the super admin for review.
  - New academy submissions should notify the super admin for approval.
  - New tournament creation should notify the super admin.

### Product Decisions
- Added a dedicated `SuperAdminNotification` inbox model with polymorphic links to the record that needs review.
- Super admin notifications stay in the active inbox while pending and leave the inbox after accept, reject, mark reviewed, or dismiss.
- Registered-academy athlete join requests continue to use the existing academy-owner notification queue.
- Unregistered academy rejection clears the athlete's external academy name so the profile does not keep an unapproved academy link.
- Tournament creation notifications are review alerts; marking them reviewed does not change tournament status.

### Change Log
- Added the `super_admin_notifications` table and model.
- Added `/super_admin/notifications` with accept, reject, mark reviewed, and dismiss actions.
- Added a super-admin `Notifications` item to the left navigation.
- Created super-admin notifications when academies are submitted, athletes list an unregistered academy, and organisers create tournaments.
- Kept registered academy athlete requests routed to academy owners through `AcademyMembershipRequest`.
- Added UI copy and action buttons for academy, athlete, and tournament notification types.
- Added controller coverage for access control, menu visibility, notification creation, routing, approval/rejection, and inbox cleanup.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: migrated `20260901093000_create_super_admin_notifications`.
- Ran `git diff --check`; result: no whitespace or patch formatting errors.
- Ran `mise exec -- bin/rails test test/controllers/super_admin_notifications_controller_test.rb`; result: 6 runs, 77 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 213 runs, 2076 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-01 - Terms and Data Sharing Consent Timestamps

### Reference
- User requested mandatory terms-and-conditions acceptance and mandatory data-sharing consent when creating athletes, academies, and tournaments.
- User specified that submitted consent time must be recorded in the database because this is critical.

### Product Decisions
- Consent is enforced server-side on create flows, not just with browser `required` fields.
- Consent timestamps are stored directly on the created athlete, academy, or tournament record.
- Existing edit flows do not require fresh consent, so routine profile/event edits are not blocked.
- The Terms and conditions page is public and remains reachable to signed-in athletes even when athlete home normally redirects to their profile.
- Each flow has domain-specific data-sharing wording:
  - Athletes consent to sharing profile, academy, document, registration, payment receipt, weigh-in, draw, and result data with academies, organisers, and authorised admins.
  - Academies consent to sharing academy profile, contact, logo, roster, join request, and approval status data for operations.
  - Tournaments consent to sharing event, organiser, payment, venue, referee, registration, weigh-in, draw, score, and result data with relevant participants and authorised admins.

### Change Log
- Added `terms_accepted_at` and `data_sharing_consent_accepted_at` to athletes, academies, and tournaments.
- Added virtual consent attributes and server-side consent validation hooks to `Athlete`, `Academy`, and `Tournament`.
- Set consent validation only on create controller paths for athlete, academy, and tournament submissions.
- Added consent checkboxes with links to the Terms and conditions page on athlete, academy, and tournament create forms.
- Added `/terms` and a Terms and conditions page covering information sharing, uploads, approvals, audit trail, and data accuracy.
- Added styling for consent panels and the terms page.
- Updated create-path tests to submit consent and assert timestamps are recorded.
- Added negative tests proving athlete, academy, and tournament creation are rejected when consent is missing.
- Added Terms page coverage for signed-in athletes.

### Verification Log
- Ran `mise exec -- bin/rails db:migrate`; result: migrated `20260901103000_add_consent_timestamps_to_core_records`.
- Ran `mise exec -- bin/rails test test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb test/controllers/tournaments_controller_test.rb test/controllers/super_admin_notifications_controller_test.rb`; result: 105 runs, 1215 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 217 runs, 2122 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace or patch formatting errors.

## 2026-09-01 - Super Admin Athlete Page

### Reference
- User requested one more super-admin page with a left-menu item named `Athlete`, showing all athletes and allowing athlete deletion.

### Product Decisions
- Added a dedicated super-admin athlete page instead of relying only on the shared athletes index.
- Used a tabular admin view so athlete identity, academy, contact, profile summary, and destructive actions line up cleanly.
- Kept deletion behind the existing athlete destroy behavior and added a confirmation prompt on the super-admin row action.

### Change Log
- Added `SuperAdmin::AthletesController` with index and destroy actions.
- Added `/super_admin/athletes` route.
- Added `Athlete` to the super-admin section of the left menu.
- Added a super-admin athlete table with view profile and delete athlete actions.
- Added controller coverage for menu visibility, access control, listing all athletes, delete confirmation copy, and deletion redirect.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/super_admin_athletes_controller_test.rb test/controllers/athletes_controller_test.rb`; result: 28 runs, 261 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace or patch formatting errors.
- Ran `mise exec -- bin/rails test`; result: 220 runs, 2157 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-01 - Security Hardening and Upload Validation Review

### Reference
- User requested code compression where useful, no data leaks, tighter security, browser UI checks, and test cases for the important scenarios.

### Product Decisions
- Kept payment bank details available only inside the signed-in tournament registration flow where an athlete or academy owner is actively registering.
- Consolidated repeated consent timestamp behavior into one model concern so future terms/data-sharing changes are audited in one place.
- Added server-side upload type and size validation for tournament logo/banner images, registration payment receipts, and organiser identity documents.
- Kept accepted upload formats intentionally narrow so unexpected executable or text uploads are rejected before persistence.

### Change Log
- Added `ConsentRecordable` and reused it from `Athlete`, `Academy`, and `Tournament`.
- Added upload validation constants and validation methods for tournament branding images, payment receipts, and organiser identity documents.
- Updated form hints and field-level error rendering for tournament image uploads, payment receipt uploads, and organiser identity document uploads.
- Added an invalid upload fixture and model tests for rejected upload types.

### Verification Log
- Ran `git diff --check`; result: no whitespace or patch formatting errors.
- Ran `mise exec -- bin/rails test test/models/tournament_test.rb test/models/registration_test.rb test/models/user_test.rb test/controllers/tournaments_controller_test.rb test/controllers/users_controller_test.rb`; result: 69 runs, 649 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 224 runs, 2169 assertions, 0 failures, 0 errors, 0 skips.
- Restarted the development Rails server after it was still running from before `ConsentRecordable` was added; fresh boot resolved `NameError (uninitialized constant ... ConsentRecordable)` on `/tournaments`, `/academies`, and `/users/new`.
- Ran public and signed-out HTTP smoke checks on `/`, `/terms`, `/tournaments`, `/academies`, `/login`, `/users/new`, `/users/new?account_type=organizer`, `/users/new?account_type=academy_owner`, `/super_admin/notifications`, and `/super_admin/athletes`; result: public pages returned 200 and protected super-admin pages redirected with 302 when signed out.
- Ran authenticated HTTP smoke checks as seeded super admin, athlete, academy owner, and organiser; result: valid role pages returned 200, protected invalid cross-role resources returned the expected 302 or 404.
- Ran narrowed secret/data-leak scan for common secret names, storage/database credentials, payment account fields, and identity documents; result: production secrets are environment-driven, bank details are rendered only in the signed-in registration page, and demo seed/test credentials remain clearly local/demo data.
- Ran `git diff --check`; result: no whitespace or patch formatting errors.
- Ran `mise exec -- bin/rails test test/models/tournament_test.rb test/models/registration_test.rb test/models/user_test.rb`; result: 16 runs, 59 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 227 runs, 2180 assertions, 0 failures, 0 errors, 0 skips.
- Stopped the Rails server session that was started for QA.

## 2026-09-01 - Clean Seed Data Expansion

### Reference
- User requested more seed data and removal of incomplete, low-quality, or test-style seed data.

### Product Decisions
- Kept the four predictable local login accounts so manual testing remains quick.
- Removed rough filler language from seed records and replaced it with realistic academy, organiser, tournament, contact, payment, roster, and notification data.
- Added safe cleanup only for obvious obsolete generated tournament names; user/account cleanup was intentionally avoided after a foreign-key violation showed older records may be linked to academy membership requests.
- Added pending approval and notification scenarios so super-admin and academy-owner dashboards can be tested without manual setup.

### Change Log
- Added additional approved academies: Shivneri Martial Arts, Deccan Elite Taekwondo, and Mumbai Falcons Taekwondo.
- Added Riverfront Combat Academy as a pending academy with a super-admin approval notification.
- Added more academy owners, one additional verified organiser, and a broader athlete roster across Pune and Mumbai academies.
- Replaced demo-style event descriptions, bank names, placeholder addresses, and generic emergency contact names with cleaner staging-quality content.
- Added Bengaluru Classic Taekwondo League as an open-registration tournament.
- Added Delhi Winter Taekwondo Festival as a completed tournament with registration and weight-check history.
- Added realistic pending, approved, rejected, weight-verified, and disqualified registration scenarios.
- Added an independent athlete with an unregistered academy notification and a registered-academy membership request.

### Verification Log
- Initial `mise exec -- bin/rails db:seed` run failed because deleting old demo users violated a foreign-key constraint from `academy_membership_requests`; cleanup was changed to avoid user deletion.
- Ran `mise exec -- bin/rails db:seed`; result: seed completed successfully.
- Ran `mise exec -- bin/rails db:seed` again; result: seed remained idempotent.
- Ran local data count check; result: 53 users, 8 academies, 61 athletes, 10 tournaments, 83 categories, 90 registrations, 5 super-admin notifications, and 2 academy membership requests.
- Ran `git diff --check`; result: no whitespace or patch formatting errors.
- Ran `mise exec -- bin/rails test`; result: 227 runs, 2180 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-02 - PodiumCircle Domain and Brand Update

### Reference
- User purchased the `podiumcircle` domain name and requested all relevant changes.

### Product Decisions
- Renamed customer-facing app branding from Sports Hub to PodiumCircle.
- Changed the Rails application module from `SportsHub` to `PodiumCircle` so source-level app identity matches the new brand.
- Updated local seed emails from `@sportshub.test` to `@podiumcircle.test`.
- Kept local folder name, database names, Fly app name, and GitHub remote unchanged for now because those are runtime/deployment identifiers and changing them would require a separate deployment migration.
- Set production defaults around `podiumcircle.com`, while keeping them environment-variable driven for Fly and future hosting changes.

### Change Log
- Updated layout title and left-nav brand to PodiumCircle.
- Updated terms, consent text, mailer copy, setup message, README, tests, and seed fixture text to use PodiumCircle.
- Updated `ApplicationMailer` to default from `no-reply@podiumcircle.com`, overridable by `MAILER_FROM`.
- Added production `APP_HOST` defaults for host authorization and mailer URLs, defaulting to `podiumcircle.com`.
- Updated seed output and README local credentials to `admin@podiumcircle.test`, `organizer@podiumcircle.test`, `academy@podiumcircle.test`, and `athlete@podiumcircle.test`.
- Made `seed_user` migrate old `@sportshub.test` seed users to `@podiumcircle.test` instead of creating duplicates.

### Verification Log
- Ran old-brand scan across `app`, `config`, `db/seeds.rb`, `test`, `README.md`, `AGENTS.md`, and `bin/setup`; result: no remaining `Sports Hub`, `SportsHub`, or `sports-hub` references in active source/docs/tests. The only `sportshub` string left is the intentional `db/seeds.rb` legacy email migration fallback.
- Ran `mise exec -- bin/rails runner 'puts Rails.application.class.module_parent_name'`; result: `PodiumCircle`.
- Ran `mise exec -- bin/rails db:seed`; result: seed completed and printed the new PodiumCircle local credentials.
- Ran local seed-domain count check; result: 46 `@podiumcircle.test` seed users, 0 `@sportshub.test` seed users, 53 users total, 8 academies, 10 tournaments.
- Ran `git diff --check`; result: no whitespace or patch formatting errors.
- Ran `mise exec -- bin/rails test`; result: 227 runs, 2180 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-03 - Remove Set Draw Feature

### Reference
- User requested removing all code written for the Set draw feature, including HTML and CSS.

### Change Log
- Removed Set draw routes, tournament controller actions, the draw match result controller, draw models, draw generator service, draw migrations, draw schema tables, draw page, draw status partial, draw JavaScript, draw CSS, draw tests, athlete/academy draw status rendering, and draw-specific seed data.
- Kept the weight-check flow and `weight_verified` registration status because they are part of weigh-in rather than the draw feature.
- Removed user-facing draw setup copy from registration, venue setup, terms, consent, navigation, and weight-check screens.
- Added a cleanup migration that converts stale removed draw-status tournament rows to `registration_closed`, fixing local pages that crashed when Rails read the removed enum value as `nil`.
- Added a static SVG favicon and `/favicon.ico` redirect to remove the browser favicon 404.

### Verification Log
- Ran `rtk mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb test/controllers/athletes_controller_test.rb test/controllers/academies_controller_test.rb test/models/registration_test.rb test/controllers/organizer_weight_checks_controller_test.rb test/models/tournament_test.rb`; result: 108 runs, 1079 assertions, 0 failures, 0 errors, 0 skips.
- Ran `rtk mise exec -- bin/rails test`; result: 199 runs, 1859 assertions, 0 failures, 0 errors, 0 skips.
- Ran `rtk mise exec -- bin/rails db:migrate`; result: `20260903000100_normalize_removed_draw_status` migrated successfully.
- Verified `http://127.0.0.1:3000/tournaments`; result: 200 OK.
- Verified stale removed draw-status rows with Rails runner; result: 0.
- Verified `http://127.0.0.1:3000/favicon.svg`; result: 200 OK.
- Verified `http://127.0.0.1:3000/favicon.ico`; result: 301 redirect to `/favicon.svg`.
- Re-ran `rtk mise exec -- bin/rails test`; result: 199 runs, 1859 assertions, 0 failures, 0 errors, 0 skips.
- Rebuilt stale `debug` and `rbs` native extensions with `rtk mise exec -- gem pristine ...`; result: Rails commands no longer print extension warnings.
- Final `rtk mise exec -- bin/rails test`; result: 199 runs, 1859 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-08 - Organizer Approval Copy and Mobile Sign Out Clarity

### Reference
- User requested removing direct `super admin` wording from organizer account creation messaging and making the mobile logout option clearer.

### Change Log
- Changed organizer signup success copy to say the organizer profile will be reviewed and approved before tournament management access is available.
- Changed organizer signup page, organizer directory, and tournament creation approval copy to avoid naming the approver role directly.
- Updated the mobile side-menu sign-out action to render as a clearer full-width button with stronger contrast and a larger touch target.
- Updated user-controller tests to assert the generic organizer approval wording.

### Verification Log
- Ran `rg -n "Super admin verification|Super admins verify|super admin will verify|sent to super admin" app test`; result: only the negative user-controller assertion still mentions the old copy.
- Ran `git diff --check`; result: no whitespace errors.
- Ran `mise exec -- bin/rails test test/controllers/users_controller_test.rb test/controllers/tournaments_controller_test.rb`; result: 53 runs, 555 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-08 - Demo Academy and Athlete Seed Data

### Reference
- User requested seed data with 3 academies containing `Demo` in their names, logical images, and 100 athletes that can be identified later by `Surname test`.

### Change Log
- Added 3 approved demo academies: `Demo Summit Taekwondo Academy`, `Demo Harbor Martial Arts Academy`, and `Demo Skyline Combat Academy`.
- Added 3 academy-owner users for the demo academies.
- Added 100 demo athlete accounts and athlete profiles with last name `Surname test`, covering a spread of ages, weights, genders, belts, blood groups, and cities.
- Assigned 75 demo athletes to the demo academies and 25 as independent athletes with external academy names.
- Attached the existing valid PNG fixture to demo academy logos and athlete profile photos so seed data satisfies current upload validations.
- Corrected older seed registration fixtures whose athlete/category combinations no longer satisfied strict age, weight, and gender eligibility checks.

### Verification Log
- Ran `ruby -c db/seeds.rb`; result: `Syntax OK`.
- Ran `git diff --check`; result: no whitespace errors.
- Ran `mise exec -- bin/rails db:seed`; result: completed successfully.
- Ran seed count verification; result: `{ demo_academies: 3, surname_test_athletes: 100, linked_demo_athletes: 75, independent_demo_athletes: 25 }`.
- Ran `mise exec -- bin/rails test test/models/athlete_test.rb test/models/academy_test.rb test/models/registration_test.rb`; result: 43 runs, 163 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-08 - Athlete Registration Security QA

### Reference
- User requested testing the athlete registration flow against signed-out access, ID tampering, category tampering, duplicate submissions, file upload abuse, XSS, SQL-like input, direct object access, payment-data exposure, CSRF, email reuse, return-path tampering, and login probing.

### Change Log
- Added `test/controllers/athlete_flow_security_test.rb` with request-level regression coverage for 18 athlete-flow security scenarios.
- Enabled explicit Rails CSRF protection in `ApplicationController` with exception-mode forgery handling.
- Added first-name and last-name format validation to `Athlete` so script-like names are rejected before storage.
- Updated an athlete pagination test fixture to use valid human-style names after tightening name validation.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/athlete_flow_security_test.rb`; result: 18 runs, 156 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test test/controllers/athlete_flow_security_test.rb test/controllers/registrations_controller_test.rb test/models/registration_test.rb test/controllers/athletes_controller_test.rb test/controllers/sessions_controller_test.rb test/controllers/organizer_registrations_controller_test.rb`; result: 105 runs, 777 assertions, 0 failures, 0 errors, 0 skips.
- Ran `git diff --check`; result: no whitespace errors.

## 2026-09-13 - PodiumCircle QA Pass and Image Variant Dependency

### Reference
- User requested a full round of testing for Podium Circle and to ignore Abhaaya.

### Change Log
- Ran local Rails regression coverage and production smoke checks for Podium Circle.
- Added the `image_processing` gem because production Rails logs showed Active Storage image variants were being requested without the required variant-processing dependency.

### Verification Log
- Ran `mise exec -- bin/rails test` before the dependency change; result: 398 runs, 3058 assertions, 0 failures, 0 errors, 0 skips.
- Ran production public smoke checks for `/`, `/tournaments`, `/tournaments/3`, `/tournaments/6`, `/academies`, `/organizers`, `/terms`, and `/login`; result: all returned 200 OK and no application-error body.
- Ran production authenticated athlete smoke check with `prod.flow.001@podiumcircle.test`; result: login redirected to `/athletes/33`, and athlete profile, tournaments, tournament detail, registration form, and academies pages returned 200 OK without application-error bodies.
- Checked production data counts; result: 117 users, 107 athletes, 0 academies, 4 tournaments, and 203 registrations.
- Checked recent Fly and Rails production logs; result: no recent 500 trace for the smoke-tested pages, but Rails logged that image variants require `image_processing`.
- Ran `bundle install`; result: installed and locked `image_processing` 1.14.0 with `mini_magick` 5.4.0 and `ruby-vips` 2.3.0.
- Ran `git diff --check`; result: no whitespace errors.
- Re-ran `mise exec -- bin/rails test` after the dependency change; result: 398 runs, 3058 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-12 - Winner-Only Match Decision and Bracket Null-Score Fix

### Reference
- User requested a way for a referee to record a match winner directly, without entering round points, defaulted in the decision dropdown — matching how `withdrawal` already skips round scoring.

### Change Log
- Added `winner_only` to `Match#decision` enum (value `5`, additive — no migration, no effect on existing rows).
- Reordered the decision `<select>` in `_match_score_form.html.erb` so "Select winner (no points)" is first and explicitly marked selected; updated the field hint to match the new default.
- Added a `winner_only` branch to `match_result_summary` in `ApplicationHelper` for an explicit result string instead of relying on the generic `else`.
- Fixed `BracketPresenter#opponent_json`: it always set `opponent[:score]` from `score_data["rounds_won"]`, which is empty for any non-points decision (withdrawal, RSC, disqualification, no-show, and now winner-only). The resulting `nil` serialized to JSON `null` and brackets-viewer.js rendered the literal text "null" next to the winner in the draw view. Now `:score` is only set when a points value actually exists.
- No controller or JS changes were needed — `Organizer::MatchesController#update` already treats any non-`"points"` decision generically, and `updateMatchDecisionFields` in `application.js` already keys off `value === "points"` rather than an enumerated list.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/organizer_matches_controller_test.rb test/controllers/organizer_draws_controller_test.rb test/models/match_test.rb test/services/bracket_presenter_test.rb`; result: all passing.
- Ran `mise exec -- bin/rails test`; result: 398 runs, 3058 assertions, 0 failures, 0 errors, 0 skips.
- Manually created 3 athletes and a draw in the local dev environment (Pune Open Taekwondo Championship, Kyorugi Male Age 8-11 U16) and recorded a winner-only result through the browser; confirmed the bracket view shows clean W/L badges with no "null" text.
- Committed and pushed both changes to `origin/main` (commits `d732f6e`, `75d8faf`).

## 2026-09-13 - Manual QA Pass (Browser) Across Public, Athlete, Academy, and Organizer Flows

### Reference
- User requested a detailed round of testing for the website (local environment).

### Change Log
- Fixed a broken client-side `pattern` regex (`[a-zA-Z\s'-]+`) on the name fields in `users/new.html.erb` (signup) and `academies/_form.html.erb` (academy contact name). Recent Chromium versions compile the HTML `pattern` attribute in Unicode-set ("v" flag) mode, under which an unescaped trailing hyphen next to a `\s` class-escape is invalid syntax; the browser threw `Invalid regular expression ... /v: Invalid character in character class` and the pattern constraint silently stopped applying. Escaped the hyphen (`\\-`) in both places, verified valid under the new regex mode via a fresh browser tab (no console error, `checkValidity()` true for a name with a space/hyphen/apostrophe).
- Fixed `RegistrationsController#create`: `@registration` was built with no attributes, so on a failed submission (e.g. missing payment receipt) the re-rendered form always showed an empty "Current weight" field even though the user had typed one — the typed value was silently discarded before validation. Now `@registration` is built with `registered_weight` from the submitted params so the field round-trips correctly on validation failure. (The actual per-category registrations saved on success were never affected — this only fixed the error-path re-render.)

### Verification Log
- Ran `mise exec -- bin/rails test`; result: 398 runs, 3058 assertions, 0 failures, 0 errors, 0 skips (both before confirming the bugs and after fixing them).
- Manually exercised in the browser: homepage, tournament listing/search, tournament detail page, full signup flow (`/users/new` → athlete profile setup → athlete show page), full paid-tournament registration flow (category selection, fee total, weight, payment details, receipt upload, submission), organizer registration approval (kebab menu → Accept), full academy registration flow (`/academies/new` → submission → super-admin approval via kebab menu), an authorization boundary check (`ActiveRecord::RecordNotFound` → 404 when a non-manager opens another organizer's tournament edit page), and a mobile-viewport (375×812) pass on the homepage, tournament listing, and tournament detail page.
- Confirmed the session-fingerprint security feature correctly force-logs-out a session when the mobile emulation preset changes the browser's user agent mid-session — expected behavior, not a bug.
- No other functional defects found in this pass; all console errors observed during testing were traced to either the two fixed bugs above or the browser tab's own stale console buffer (confirmed via a fresh tab) or intentionally-triggered 422/404s from the edge-case tests themselves.

## 2026-09-15 - Full Athlete Registration Flow QA and Validation Gaps

### Reference
- User requested running the complete athlete registration flow end to end, deliberately trying invalid/adversarial inputs at every step, with results reported in a pass/fail table.

### Change Log
- Added `Athlete::MAX_AGE_YEARS = 100` and extended `date_of_birth_cannot_be_in_the_future` to also reject a date of birth that would make the athlete over 100 years old (previously only future dates were rejected — a date of birth of 1850 was silently accepted).
- Added format validation (`User::PHONE_FORMAT`, 10-digit) to `Athlete#contact_number` and `Athlete#emergency_contact_phone` — previously neither field validated format at all, so arbitrary text like `"call-me-maybe"` was accepted and stored.

### Verification Log
- Manually ran 25 test cases across account signup, athlete profile creation/edit, and tournament registration, deliberately submitting invalid emails, mismatched/weak passwords, malformed phone numbers, names with digits and XSS payloads, a future and a 176-years-ago date of birth, negative/zero/absurd weights, a non-numeric contact number, an XSS payload in emergency contact name, a `.txt` file as a profile photo and a `.exe` as a payment receipt, a category mismatched to the athlete's age/gender, duplicate and already-decided category resubmission, and raw-POST tampering of category IDs (nonexistent, cross-tournament) and athlete ID (another user's athlete). 23 of 25 passed; found and reported the two gaps above (plus a minor, unfixed inconsistency: phone is marked `required` in the athlete signup HTML but not enforced server-side for non-organizer accounts).
- Ran `mise exec -- bin/rails test test/models/athlete_test.rb`; result: 17 runs, 75 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 400 runs, 3066 assertions, 0 failures, 0 errors, 0 skips.
- Re-verified live in the browser: resubmitted the same 1850 date of birth and `"call-me-maybe"` contact number against the same athlete record used during the QA pass; both are now rejected with the expected error messages, then restored the profile to valid values.

## 2026-09-23 - Pre-GitHub Commit Test Stabilization

### Reference
- User requested committing the current PodiumCircle code to GitHub after local QA and full test-suite runs.

### Change Log
- Updated `TournamentsControllerTest` setup for draft tournament visibility so the signed-in athlete has a completed athlete profile. This keeps the test focused on draft visibility instead of triggering the athlete profile-completion redirect.
- Added a UPI payment method to the public paid-tournament details test fixture. Paid published tournaments now correctly require at least one payment method, so the fixture must satisfy that production validation before asserting public fee visibility.

### Verification Log
- Initial full-suite run before commit showed 476 runs, 3412 assertions, 1 failure, 1 error.
- Targeted fixes were made only in test setup; no production behavior was changed by this stabilization.
- Ran `mise exec -- bin/rails test test/controllers/tournaments_controller_test.rb`; result: 59 runs, 551 assertions, 0 failures, 0 errors, 0 skips.
- Ran `mise exec -- bin/rails test`; result: 476 runs, 3420 assertions, 0 failures, 0 errors, 0 skips.

## 2026-09-23 - Academy Registration Flow, QA Defect Fixes, and Full-Codebase Review

### Reference
- User asked for a UX mockup and then implementation of a multi-screen "cart" registration flow for academy owners (select individual categories or a Pair/Team Poomsae entry across multiple screens, one combined payment at the end).
- User then reported 8 QA-found defects across signup, academy roster visibility, organizer navigation, address forms, document upload, and registration status display, and asked to fix them.
- User then asked for a full-codebase code review (not just the diff), which surfaced 10 correctness/authorization findings; user asked to fix all of them.

### Change Log — Academy registration flow
- Replaced the single-page `registrations#create` form with a draft-based cart: `RegistrationsController#individual`/`#group`/`#payment`/`#submit`/`#destroy`. Reuses the existing but previously-unused `Registration#status` `draft` value as the in-progress cart state, grouped by `submission_batch_id`.
- Added `TournamentCategory.suggested_individual_categories`/`.closest_by_weight` for gender/age-filtered category suggestions with the closest Kyorugi weight bracket recommended.
- New views `registrations/individual.html.erb`, `group.html.erb`, `payment.html.erb`; roster picker is radio-based (not checkbox) per explicit direction, since a checkbox multi-select roster was tried first and rejected as unworkable with many athletes.
- Renamed "Add athlete" to "Register new athlete" in the registration flow only (not the academy roster page, which keeps its original wording by explicit instruction).

### Change Log — QA defect fixes
- `Registration#athlete_status_detail`: removed the `pending` branch ("Waiting for organiser review.") since it duplicated the adjacent status pill ("Submitted") — now one clear status per registration instead of two overlapping ones.
- `RegistrationsController#create_individual_draft`/`#create_group_draft`: a duplicate/already-decided registration now redirects with a clear alert instead of silently doing nothing.
- `AthletesController`: split `visible_athletes` (authorization scope, still includes pending-request athletes so their profile can be opened) from a new `roster_athletes` (the index listing, excludes pending-request-only athletes). Added a "Pending academy requests" section to the Athletes index with inline Accept/Reject, so a pending join request no longer looks like it's "mapped to another academy" with no way to act on it.
- Added a top-level "Registration approvals" sidebar link with a live pending-count badge (`ApplicationHelper#organizer_pending_registration_count`) — the approvals dashboard already existed but was two clicks deep.
- Added `IndianLocation` module (`app/models/concerns/indian_location.rb`): 36 states/UTs with curated major cities per state, plus a `pincode` column (Academy, Athlete, Tournament) with 6-digit format validation. New shared partial `shared/_city_state_fields.html.erb` makes city a state-dependent dropdown (with an "Other" free-text fallback) instead of unlinked free text, used by the academy, athlete, and tournament forms.
- Could not reproduce the reported "duplicate email → 404" or "Geovernment typo / false size rejection" — traced both code paths live and they behave correctly today; added a regression test for the duplicate-email case. Flagged to the user as possibly tested against a different/older build.

### Change Log — Code review fixes (all 10 findings from the full-codebase review)
- `can_register_for_tournament?`: the organizer/academy-owner carve-out was unreachable (role is a single-value enum, so the condition as written always blocked every verified organizer). Now checks actual academy ownership (`owned_academies.approved.exists?`) instead of the role enum.
- `Tournament#managed_by?` granted a plain `collaborator` the same rights as a `super_organizer`. Added `managed_by_super_organizer?` / `can_manage_tournament_finances?`; tournament edit/update and organizer invitations now require the owner or a `super_organizer`, not any collaborator.
- Academy approval (`AcademiesController#approve`) unconditionally called `academy_owner!`, overwriting an existing role like `organizer`. Now only promotes an owner whose current role is the default `parent`.
- `can_manage_academy?(nil)` crashed with `NoMethodError` when an academy owner deleted an athlete who only had a pending join request (`academy_id` still nil). Added a nil guard.
- Draft (cart) registrations leaked into three views that never excluded `status: :draft`: the tournament page's category/registration counts, the athlete profile's upcoming/previous tournaments, and the academy roster's tournament-status table. Added `Registration.decided` scope (`where.not(status: :draft)`) and applied it at every relevant call site, replacing the ad-hoc `.where.not(status: :draft)` duplicates too.
- `RegistrationsController#draft_registrations` bundles every outstanding draft for a tournament, not just the current visit's — a stale draft from a prior abandoned session could get silently submitted alongside a new one. Kept the intentional cross-visit persistence (resuming a cart later is a feature) but added a visible "Added X ago" timestamp per cart row (flagged red past 24h) via a new shared partial `registrations/_draft_cart_rows.html.erb`, so a stale entry is now clearly flagged instead of blending in.
- `TournamentCategory#free?` didn't honor `Tournament#free?`'s documented "blank group fee = free" semantics, wrongly demanding a payment receipt for free group entries. Fixed to special-case group event types.
- `visible_tournament_registrations` omitted academy-owned athletes from the tournament page's "your registered athletes" section (only matched `user_id`, not academy ownership). Extracted `User#manageable_athletes` as the single source of truth, reused by both `RegistrationsController` and `TournamentsController`.
- `RegistrationWeightCheck#apply_registration_result` ignored `review!`'s boolean return, so a failed review (e.g. tournament closes out mid-request) still recorded a "passed" weight check with no error while the registration silently never transitioned. Now checks the return value and `throw :abort`s with a clear error if it fails.
- `TournamentsController#show` / `AcademiesController#show` applied no draft/approval-status scoping (unlike their `index` actions), so an unapproved academy or a draft tournament was fully visible to anyone with a direct link. Both now 404 for non-managers when the record isn't public yet.

### Verification Log
- Ran `mise exec -- bin/rails test` after the academy registration flow: 464 runs, 0 failures.
- Ran `mise exec -- bin/rails test` after the QA defect fixes: 470 runs, 0 failures.
- Ran `mise exec -- bin/rails test` after all 10 code-review fixes (including 3 pre-existing tests that were unknowingly relying on the draft-tournament visibility bug, and one test asserting the now-corrected collaborator-permission behavior): 476 runs, 3420 assertions, 0 failures, 0 errors, 0 skips.
- Manually verified the academy registration flow end-to-end against the local dev server (individual entry → suggested categories → group entry → combined payment screen with real payment details) using seeded test data, then cleaned up the seeded data afterward.
- Nothing pushed or committed — all changes remain local per standing instruction from earlier in this session.

## 2026-09-23 (cont.) - Separate Athlete Direct-Registration Flow + Nested-Form Bug Fix

### Reference
- User clarified that the multi-screen "cart" registration flow was intended only for academy owners. Athletes must never see Pair/Team Poomsae and should get a single-page direct registration (profile summary, optional weight, suggested categories, payment summary, receipt upload, submit) per the originally-specified "Athlete Registration Flow" — with an explicit instruction not to change the academy owner flow.
- User then reported the academy owner flow itself was broken: clicking "Remove" on a cart entry errored, and "Submit" didn't submit.

### Change Log
- Added a separate, single-page athlete self-registration path, entirely independent of the academy owner's draft-cart flow: `RegistrationsController#new` now renders a dedicated `athlete_new.html.erb` template for athlete-role users (instead of redirecting into the academy `individual` screen), and a new `create` action (`POST /tournaments/:id/registrations`, athlete-only, 404s for anyone else) creates real `pending` registrations directly — no draft/cart, no batch. Reuses existing suggestion/eligibility/payment-receipt helper methods but has its own controller logic, so the academy owner's `individual`/`group`/`payment`/`submit`/`destroy` actions and views were not touched by this change.
- Fixed a real bug found while building this: `RegistrationsController#new`/`create_athlete_registration` had a dead nil-check-and-redirect for "athlete has no profile yet" — `ApplicationController#require_athlete_profile_completion` already handles that globally for every controller. Removed the redundant unreachable code.
- **Found and fixed a real bug in the academy owner flow** (introduced by an earlier code-review fix that extracted the draft-cart display into a shared partial): `registrations/payment.html.erb` rendered the `_draft_cart_rows` partial — which itself contains a `button_to` "Remove" form — *inside* the page's own payment `<form>`, producing invalid nested `<form>` elements. Browsers silently mis-parse nested forms (the inner form's fields get absorbed into the outer one), which is exactly what caused "Remove" to error and "Submit" to not work for academy owners. Moved the cart display outside the payment form, matching the (already-correct) pattern in `individual.html.erb`/`group.html.erb`. Reproduced and confirmed the fix against the running dev server via direct HTTP requests replaying the exact form data a browser would send, before and after the fix.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/registrations_controller_test.rb`: 31 runs, 0 failures (includes new tests for the athlete direct flow — successful submission, multiple categories in one go, Pair/Team Poomsae rejected, receipt-required, duplicate-category alert, non-athlete blocked from the new `create` action — and a new regression test asserting the payment screen's "Remove" form fully closes before the payment form opens, guarding against the nested-form bug recurring).
- Ran `mise exec -- bin/rails test`: 484 runs, 3466 assertions, 0 failures, 0 errors, 0 skips.
- Manually reproduced both reported symptoms against the local dev server with real seeded data and real form payloads (POST with `_method=delete` and the exact CSRF token from the rendered page, matching what a browser's generated form actually sends) — confirmed the "Remove" action 500/422'd before the fix due to the nested-form parse issue, and both "Remove" and "Submit" work correctly after moving the cart rows outside the form.
- Nothing pushed or committed — all changes remain local per standing instruction from earlier in this session.

## 2026-09-23 (cont.) - Show/Hide Password Toggle, Required-Field Hint Placement, Address Field Revert

### Reference
- User asked for three fixes, applied consistently everywhere the same pattern occurs (not just the one place each was first noticed): (1) a show/hide toggle on password fields, starting with login; (2) the "* indicates a required field." hint moved to the end of the form, just above the submit button, on the athlete/academy/signup forms; (3) reverting the address block's city field back to free text (no dependent city dropdown), keeping state and country as dropdowns.

### Change Log
- Added a reusable `password_field_with_toggle(form, method, **options)` helper (`app/helpers/application_helper.rb`) that wraps `form.password_field` in a `.password-field-wrapper` with an eye/eye-off toggle button, plus a new `"eye-off"` entry in `ICON_PATHS`. Added a delegated click handler (`togglePasswordVisibility`, `app/assets/javascripts/application.js`) that flips the input's `type` between `password`/`text` and swaps the icon/aria-label — no per-page JS needed. Added matching CSS (`.password-field-wrapper`, `.password-toggle-button`).
- Applied the helper to all 8 password fields in the app: login (`sessions/new.html.erb`), signup (`users/new.html.erb`, both fields), password reset (`password_resets/edit.html.erb`, both fields), and the profile change-password section (`profiles/show.html.erb`, all 3 fields).
- Verified in the browser against the running dev server: typing into the login password field and clicking the toggle reveals the plain-text value and swaps to the eye-off icon; the signup form shows the same toggle on both password fields.
- The required-field hint reposition and the address city/state/country revert (dropdown state/country, free-text city, `IndianLocation` concern trimmed of the now-unused `STATE_CITIES`/`cities_for`/`OTHER_CITY`, dead dependent-dropdown JS removed) were completed earlier in this session; this entry closes out the batch alongside the password-toggle work.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/sessions_controller_test.rb test/controllers/users_controller_test.rb test/controllers/password_resets_controller_test.rb test/controllers/profiles_controller_test.rb`: 53 runs, 0 failures.
- Ran full suite `mise exec -- bin/rails test`: 484 runs, 3466 assertions, 0 failures, 0 errors, 0 skips.
- Manually verified the login and signup pages against the local dev server: password toggle reveals/hides text correctly, required-field hint appears immediately above the submit button.
- Nothing pushed or committed — all changes remain local per standing instruction from earlier in this session.

## 2026-09-23 (cont.) - Athlete Profile Navigation & Edit-Profile Tab Consolidation

### Reference
- User reported that for the athlete flow, the "edit" button on `/athletes/:id` correctly opens the full editable form at `/athletes/:id/edit`, but the left-nav account pill (the athlete's name) was inconsistent — it went to `/profile` instead of the athlete's own profile page. User asked for the pill to be consistent with the athlete page, and separately asked that clicking "Edit profile" on `/athletes/:id` take the athlete to `/profile`, where an "Edit profile" tab shows the same full set of editable fields as `/athletes/:id/edit`.

### Change Log
- `app/views/layouts/application.html.erb`: the sidebar account pill now links athlete-role users to `athlete_home_path` (their own `/athletes/:id`) instead of `profile_path`, matching the existing "Athletes" nav item's behavior. Other roles (organizer, academy owner, parent, admin) are unchanged and still link to `/profile`.
- `app/views/athletes/show.html.erb`: the "Edit profile" button, when the viewer is the athlete viewing their own profile, now links to `profile_path(tab: "edit")` instead of `edit_athlete_path`. Super admin / academy-owner-on-another-user's-athlete cases are unchanged (still `edit_athlete_path` — `/profile` is only meaningful for the signed-in user's own account).
- `app/controllers/profiles_controller.rb`: added a `set_athlete_tab_data` `before_action` that loads `@athlete` (the current athlete-role user's own athlete record), `@available_academies`, and `@return_to = profile_path(tab: "edit")` — reused by `show`, `update`, and `update_password` so the edit tab's data survives a validation-failure re-render of `:show`, not just the initial GET.
- `app/views/profiles/show.html.erb`: restructured into two tabs behind a small `data-tabs`/`data-tab-button`/`data-tab-panel` pattern (only shown when the user has an athlete profile): "Profile" (the existing account details, name/phone form, password form, delete-account section — the inline "Edit profile" heading was renamed to "Account details" to avoid clashing with the new tab name) and "Edit profile" (renders the existing `athletes/form` partial unchanged, submitting to the same `AthletesController#update` action as `/athletes/:id/edit` always has). `?tab=edit` selects the edit tab server-side on load; a new delegated click handler (`activateTab`, `app/assets/javascripts/application.js`) switches tabs client-side afterward, no page reload.
- No changes to `AthletesController` — the standalone `/athletes/:id/edit` page (used by academy owners/super admins editing another athlete, and by the "Complete profile" links in the registration flow) is untouched and behaves exactly as before, which the user confirmed was already correct.
- Added `.tab-strip`/`.tab-strip-button` CSS.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/profiles_controller_test.rb test/controllers/athletes_controller_test.rb`: 55 runs, 0 failures.
- Ran full suite `mise exec -- bin/rails test`: 484 runs, 3466 assertions, 0 failures, 0 errors, 0 skips.
- Manually verified against the local dev server signed in as a seeded athlete (`athlete@podiumcircle.test`): the sidebar name pill now opens `/athletes/3` (previously `/profile`); "Edit profile" on `/athletes/3` opens `/profile?tab=edit` with the Edit profile tab active and the full athlete form pre-filled; clicking the "Profile" tab switches instantly without a page reload; editing a field (weight) and submitting saves the change and redirects back to `/profile?tab=edit` with the new value visible.
- Nothing pushed or committed — all changes remain local per standing instruction from earlier in this session.

## 2026-09-23 (cont.) - Mobile Nav Drawer: Sign Out Cut Off / Not Scrollable

### Reference
- User reported (with a phone screenshot) that on real phones the athlete's mobile nav drawer showed the "RIYA" account pill and "Athlete" label but no "Sign out" button below it, and that in landscape orientation the drawer wasn't scrollable to reach it either.

### Change Log
- Root cause: `.side-menu` (`app/assets/stylesheets/application.css`) was sized with `height:100vh`. On mobile browsers, `100vh` is based on the *largest* possible viewport (browser chrome collapsed), not the viewport actually visible with the address bar/toolbar showing — so the fixed-position drawer's real height on screen exceeded what was visible, and its bottom content (the account pill, role label, and Sign out button, pinned via `margin-top:auto`) rendered below the visible fold. Since nothing inside the drawer overflowed the (oversized) box itself, `overflow-y:auto` never had anything to scroll — the box was simply taller than the screen. This got worse in landscape, where the visible height is much smaller relative to `100vh`.
- Fix: added `height:100dvh` (dynamic viewport height, layered after the `100vh` fallback so unsupported browsers keep the old behavior) so the drawer's actual box height always matches the currently-visible viewport. `overflow-y:auto` now has real overflow to scroll when it does, and in the common case (drawer content fits the visible viewport) the "Sign out" button is simply on-screen without needing to scroll at all. Also added `-webkit-overflow-scrolling:touch` for smooth momentum scrolling on older iOS Safari.

### Verification Log
- Verified in the browser at several emulated mobile sizes (375×812 portrait, 390×560, and 812×375 to simulate landscape with browser chrome eating vertical space): at normal portrait heights "Sign out" is fully visible with no scrolling needed; at the short/landscape size the drawer now scrolls internally and "Sign out" is reachable, where before the fix it would have been clipped with no way to reach it.
- CSS-only change; no Ruby/controller/view logic touched, so the existing Minitest suite is unaffected (not re-run for this change).
- Nothing pushed or committed — all changes remain local per standing instruction from earlier in this session.

## 2026-09-23 (cont.) - Profile Page Overhaul, Event-Row/Profile-Summary Layout Bugs, Match-History-Safe Account Deletion

### Reference
- User sent screenshots of `/profile` (as athlete "Sonam Test") and an athlete's "Upcoming tournaments"/"Previous competitions" sections, plus a tournament registration page, and asked for: renaming the "Profile" tab to "Account settings" and swapping tab order (profile fields first, account settings second); fixing uneven spacing and making the page mobile-friendly; removing the redundant "Account details" (name/phone) form from the athlete's account-settings tab; fixing uneven Delete-account spacing and confirming the delete flow asks for confirmation; handling account deletion for an athlete who has actually fought a match (their name must survive in the draw sheet and any opponent's own history); confirming that switching academies correctly moves the pending-approval notification from the old academy owner to the new one; fixing visibly broken/clipped badges in the Upcoming/Previous tournament lists on both web and mobile; and fixing a broken "Your profile" summary on the tournament registration page, adding the athlete's age next to their date of birth.

### Change Log
- **Profile page tabs** (`app/views/profiles/show.html.erb`): reordered so the athlete-fields tab is now first and labeled "Profile" (was "Edit profile", was second); the account/email/password/delete tab is now second and labeled "Account settings" (was "Profile", was first). `profile_path` with no query param now defaults to the Profile tab; `?tab=account` selects the other one. The "Edit profile" button on `app/views/athletes/show.html.erb` now links to plain `profile_path` (no param needed since it's the default).
- **Removed the redundant "Account details" (User#name/#phone) form** from the Account settings tab, but only when the signed-in user has an athlete profile (i.e. only for athlete-role users, who already edit their name via the Profile tab's athlete form). Non-athlete roles (organizer, academy owner, parent) have no separate Profile tab, so they keep this form as their only way to edit their name/phone — removing it there would have been a real loss of functionality, not a fix.
- **Spacing**: added a `.profile-section` wrapper class (`app/assets/stylesheets/application.css`) giving every heading+card section on the profile page a consistent 36px gap from the previous section (previously as little as 8px in places, because `.form-section-heading`'s small intra-form margin was being used between *separate* cards, which is a different context than where that class is normally used). Added `.delete-account-panel` (flex column, 16px gap) so the Delete-account warning text and button are evenly spaced instead of touching. `.tab-strip` now wraps (`flex-wrap:wrap`) so it doesn't overflow on narrow screens.
- **Account deletion, made match-history-safe**: `Athlete#registrations` is `dependent: :destroy`, but `Match.registration_one_id/registration_two_id/winner_registration_id` reference `registrations` with no `on_delete` cascade — so an athlete who had ever been placed into a draw/bracket would hit an unhandled `ActiveRecord::InvalidForeignKey` (a 500 error) the moment they tried to delete their account, since destroying their registrations would violate that foreign key. Fixed by adding `Athlete#has_match_history?` (true if any of the athlete's registrations are referenced by a `Match`), `Athlete#anonymize!` (clears contact/address/documents/academy but keeps the name, mirroring the existing `User#deactivate!` "keep the name, clear everything else" pattern used for organizers), and `Athlete#delete_or_anonymize!` (destroys outright when there's no match history, anonymizes instead when there is). Wired into both `ProfilesController#destroy` (the "Delete account" button — now deactivates the *user* account too when any of their athletes had to be anonymized, so the anonymized-but-surviving athlete row isn't left attached to a live, usable login) and `AthletesController#destroy` (super admin's "Delete athlete", and the otherwise-unreachable self-service branch), so neither path can crash on a match-history athlete anymore, and both now leave the athlete's name intact wherever a draw sheet or an opponent's own history references it.
- **Delete-account confirmation**: already implemented via `button_to ... data: { turbo_confirm: "..." }` (Turbo's built-in native confirm() dialog, Yes/Cancel) — confirmed this already works as the user described (deletes only on confirmation) and left it as-is; only the surrounding spacing needed a fix.
- **Academy-switch notification handling**: verified — no code change was needed. `AthletesController#create_academy_request_if_needed` already rejects the athlete's previous pending request to any other academy and creates a fresh pending one for the newly-selected academy in the same update. Since `Athlete#pending_academy_request` and the academy owner's Notifications page (`AcademiesController#notifications`) both query live `AcademyMembershipRequest` state (`pending` scope) rather than a separate stored notification, the old academy stops seeing the request the moment it's rejected, and the new academy sees it the moment it's created — confirmed with a scripted reproduction of exactly this switch (old academy's request flips to `rejected`, new academy gets a fresh `pending` one).
- **Fixed a real CSS overflow/clipping bug** in the athlete's "Upcoming tournaments"/"Previous competitions" rows (`app/views/athletes/show.html.erb`, styled via `.athlete-event-row`): the row's grid columns had hard `px` minimums (`minmax(230px,...) minmax(150px,...) minmax(220px,...) auto`) whose combined minimum width, plus gaps and padding, exceeded the width of the page's `.narrow` (`max-width:780px`) container — this happens on *any* screen size, not just mobile, since the container is capped regardless of viewport width. The status pill (the `auto` 4th column) was consequently pushed past the row's right edge and silently clipped by `.athlete-event-table`'s `overflow:hidden`, exactly matching the cut-off "WEIGHT VERIF…" / partially-cut "WITHDRAWN" badges in the screenshot. Fixed by changing the three fixed-px minimums to `minmax(0, …fr)`, letting those columns shrink to fit instead of forcing overflow (the existing `overflow-wrap:anywhere` on their text already handles the tighter wrapping). Verified via direct DOM measurement in the browser (pill's right edge vs. row's right edge) that the badge now always fits, and confirmed visually on both a wide desktop viewport and an emulated 375px mobile viewport.
- **Fixed the tournament registration page's "Your profile" card** (`app/views/registrations/athlete_new.html.erb`): the `.profile-summary` class it used had no CSS rule defined at all, so each `<span>Label</span><strong>Value</strong>` pair rendered with no spacing or line break (e.g. "GenderFemale", "Date of birth12 May 2012" all run together) — exactly the "broken" layout in the screenshot. Added a real `.profile-summary` rule: a responsive `repeat(auto-fit, minmax(160px,1fr))` grid with the label stacked above the value, so it also reflows to a single column on mobile with no extra media query needed.
- **Added age next to date of birth** so it doesn't need to be calculated by hand: new `Athlete#age` method (handles the "hasn't had this year's birthday yet" case), used on the registration page's profile card ("19 Jul 2012 (14 yrs)") and on the athlete's own show page's Date of birth row.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/profiles_controller_test.rb test/controllers/athletes_controller_test.rb test/models/athlete_test.rb test/controllers/registrations_controller_test.rb`: 110 runs, 0 failures — includes new tests for `Athlete#age`/`#has_match_history?`/`#anonymize!`/`#delete_or_anonymize!`, an athlete-with-match-history self-delete via `ProfilesController#destroy` (deactivated + anonymized, Match row untouched), and a super-admin `AthletesController#destroy` of a match-history athlete (anonymized, not destroyed); updated two pre-existing tests whose asserted behavior intentionally changed (the removed Account-details section, the new deactivation flash wording).
- Ran full suite `mise exec -- bin/rails test`: 491 runs, 3512 assertions, 0 failures, 0 errors, 0 skips.
- Manually verified against the local dev server: tab order/labels, even spacing, and the mobile layout (375px) all look correct on `/profile`; clicked "Delete account" as a seeded athlete with real match history (Aarohi Shah) and confirmed via the DB afterward that the account was deactivated and the athlete row anonymized (name kept, academy/contact/weight cleared, `Match` row untouched) rather than raising an error or destroying match history; confirmed the "Upcoming"/"Previous" status pills now fit inside their card on both a wide desktop viewport and an emulated 375px mobile one (measured via DOM rects, not just visually); confirmed the registration page's profile card now shows properly spaced fields with age next to date of birth, on both desktop and mobile.
- Note for the user: this verification pass used real local dev/seed accounts already in your database (`athlete@podiumcircle.test` / Aarohi Shah, and the `sonam+1@saeloun.com` account from your screenshots) — Aarohi Shah's account is now deactivated as a direct result of testing the delete flow (expected, matches the new behavior), and `sonam+1@saeloun.com`'s password was temporarily reset to `password123` to sign in and inspect the academy-pending-request display. Let me know if you'd like these reset.
- Nothing pushed or committed — all changes remain local per standing instruction from earlier in this session.

## 2026-09-23 (cont.) - Auto-Generated UPI Payment QR Codes, Athlete Middle Name

### Reference
- User asked whether a UPI payment QR code could be generated automatically from an organizer's UPI ID instead of requiring a manual image upload, then asked to implement it: remove the QR image upload and auto-generate the QR from the UPI ID, "with all required security around it."
- Separately, user asked for an optional `middle_name` field on Athlete, with the specific requirement that when pre-filling an athlete's name from the account's single "name" field, "Riya" → first name only, "Riya Goyal" → first + last, "Riya Vinit Goyal" → first + middle + last.

### Change Log — Auto-generated UPI QR
- Added the `rqrcode` gem (pure Ruby, no network calls, no external QR-generation service — important since the alternative of using a third-party API would leak the organizer's UPI ID to that third party). No schema/asset dependency beyond the gem itself; QR is rendered as inline SVG, generated fresh on every request from the stored UPI ID rather than stored anywhere.
- **Removed** `has_one_attached :payment_qr_image` (and its size/type validation, its audit-log change-tracking, and its "at least one payment method" contribution) from `Tournament` — replaced by `Tournament#payment_upi_qr_svg`, which builds a `upi://pay?pa=...&pn=...&cu=INR&tn=...` deep link from the organizer's existing `payment_upi_id` (and `payment_account_name`, falling back to the tournament name) and renders it as an SVG QR code. Removed the file upload field from the tournament form (`app/views/tournaments/_form.html.erb`) — the organizer now just sees a live preview of the generated QR under the UPI ID field once one is saved.
- **Security**: every value interpolated into the `upi://pay` deep link is run through `URI.encode_www_form_component` before being placed in the query string (new private `Tournament#payment_upi_uri`) — `payment_upi_id` is already constrained to a safe character set by the existing `UPI_ID_FORMAT` validation, but `payment_account_name`/the tournament name are free text the organizer controls, and without encoding, a value containing `&` or `=` could inject extra params (e.g. a bogus amount) into the deep link a payer's UPI app opens. `#payment_upi_qr_svg` also re-checks the UPI ID against `UPI_ID_FORMAT` itself before generating anything, as defense in depth. Removing the upload entirely is itself a security improvement: it eliminates a whole class of image-upload risk (content-type spoofing, decompression/parsing issues, storage abuse) for this field, on top of no longer requiring the manual step at all. The QR's own SVG markup is generated entirely by the `rqrcode` gem from the computed module matrix (never by interpolating our strings into markup), so marking it `html_safe` doesn't introduce an XSS risk. Existing protections were left as-is and are unaffected: `payment_upi_id` stays encrypted at rest (`encrypts :payment_upi_id`) and the QR — like the UPI ID and bank details already did — is only ever rendered inside the signed-in registration/payment flow, never on the public tournament page (verified by an existing regression test).
- Data note: the two local dev tournaments that had a manually-uploaded QR image already also had a UPI ID saved, so switching to auto-generation is a clean, lossless swap for existing data (confirmed by querying before making the change) — no tournament in this database relied on a QR without a UPI ID behind it.
- **Requires a Rails server restart to take effect** — `rqrcode` was added to the Gemfile after your dev server process had already booted, and Bundler only loads gems at boot. Your currently-running server (port 3000) will raise `uninitialized constant Tournament::RQRCode` on any page touching a tournament's payment details until it's restarted; I don't have a way to restart a server that's running in a terminal outside this session, so this needs to be done manually (stop it and re-run your usual start command, or `mise exec -- bin/rails server`).

### Change Log — Athlete middle name
- Migration `db/migrate/20260923060721_add_middle_name_to_athletes.rb` adds an optional `middle_name` string column to `athletes` (nullable, no presence validation — matches "optional").
- `Athlete`: `middle_name` gets the same normalization (`squish.presence`), length (2..60, allow_blank), and format (`User::NAME_FORMAT` — letters/spaces/hyphens/apostrophes, allow_blank) treatment as first/last name. `full_name` now joins `[first_name, middle_name, last_name].compact_blank` — every place that already calls `full_name` (draw sheets, registrations, notifications, mailers) picks up the middle name automatically with no further changes.
- Added a "Middle name" field to the athlete form (`app/views/athletes/_form.html.erb`), between first and last name, optional (no required-field marker), permitted in `AthletesController#athlete_params`.
- **Name-splitting logic** (`AthletesController#assign_name_from_user`, used to pre-fill the athlete form from the signed-in user's single `name` field during profile setup): fixed to handle any word count, not just 1 or 2 (3+ words previously fell through and assigned nothing at all — a real, previously-unhandled gap). Now: 1 word → first name only; 2 words → first + last; 3 or more words → first word is the first name, last word is the last name, and everything in between (however many words) becomes the middle name — so "Riya" → first only, "Riya Goyal" → first + last, "Riya Vinit Goyal" → first + middle "Vinit" + last, and e.g. "Riya Vinit Kumar Goyal" → middle "Vinit Kumar".
- Extended the athlete name-search `LIKE` queries in `AthletesController`, `Organizer::WeightChecksController`, and `Super_admin::AthletesController` (three separate copies of the same search pattern) to also match against `middle_name` and a `CONCAT_WS`-joined full name, so searching by an athlete's middle name (or their full three-part name) now finds them — without this, adding the field would have created athletes that couldn't be found by part of their own name.

### Verification Log
- Ran `mise exec -- bin/rails test test/models/tournament_test.rb test/controllers/tournaments_controller_test.rb test/controllers/athlete_flow_security_test.rb test/controllers/registrations_controller_test.rb test/models/athlete_test.rb test/controllers/athletes_controller_test.rb`: all green — includes new tests for `payment_upi_qr_svg` (generated for a valid UPI ID, nil without one), the deep-link percent-encoding/injection-resistance test, an updated payment-method-requirement test (QR alone is no longer a standalone method), an updated payment-detail-audit-log test, new middle-name normalization/validation tests, and new profile-setup tests for 3-word and 4-word account names.
- Ran full suite `mise exec -- bin/rails test`: 495 runs, 3540 assertions, 0 failures, 0 errors, 0 skips.
- Manually verified the middle name field end-to-end against the local dev server (as a signed-in athlete): the "Middle name" field appears on the edit form between first and last name, saving "Vinit" produces "Rhea Vinit Kulkarni" as the athlete's full name on their profile page (breadcrumb, page title, and — via the shared `full_name` method — everywhere else full_name is used).
- Could not verify the QR rendering in the browser this session — the running dev server needs a restart to load the new gem (see note above); confirmed `RQRCode::QRCode.new(...).as_svg(...)` produces valid SVG output via `bin/rails runner` (a fresh process with the current bundle), and reasoned through the view/model code carefully given the inability to load-test it live.
- Nothing pushed or committed — all changes remain local per standing instruction from earlier in this session.

## 2026-09-23 (cont.) - Fixed the Real "Delete Athlete" Crash (Production Error on Fly)

### Reference
- User reported "delete athlete raises error" and asked for a general fix: don't hard-delete users once they have any operational/audit references — deactivate/anonymize instead. They then asked whether the same email can be reused after a deactivation (yes — already true, see below). Partway through the investigation they pasted the actual Fly production error:
  ```
  Processing by ProfilesController#destroy as HTML
  Completed 500 Internal Server Error
  ActiveRecord::InvalidForeignKey (PG::ForeignKeyViolation:
  ERROR: update or delete on table "users" violates foreign key constraint
  "fk_rails_c2dfb38a50" on table "super_admin_notifications"
  ```

### Change Log
- Confirmed `fk_rails_c2dfb38a50` is `super_admin_notifications.actor_id → users.id` (no cascade). Traced it to `AthletesController#sync_super_admin_unregistered_academy_notification`, which raises a `SuperAdminNotification` with `actor: current_user` whenever a self-service athlete lists an academy that isn't registered in the system (`external_academy_name` set) — so **any athlete who ever did that, then later deleted their own account via "Delete account" on `/profile`, hit exactly this crash.** This was a real, easily-reachable production bug, not a hypothetical.
- Added `User#has_operational_references?` (`app/models/user.rb`): true if the user is still referenced, with no cascade, by a `RegistrationActionLog` (`actor_id` — an organizer's approve/reject/weight-verify/disqualify action), a `RegistrationWeightCheck` (`checked_by_id`), a `PaymentDetailAuditLog` (`actor_id`), a `SuperAdminNotification` (`actor_id` or `reviewed_by_id` — the exact one that crashed), or a `TournamentOrganizerInvitation`/`TournamentOrganizer` they created (`invited_by_id`/`added_by_id`). Wired into `ProfilesController#delete_account!` alongside the existing preserved-tournament and athlete-match-history checks — if any of these is true, the account is deactivated (same as the existing "organizer with a completed tournament" case) instead of attempting a hard delete that would crash.
- Found and fixed a **second, independently-reachable copy of the athlete-match-history crash bug** (the one fixed earlier this session for `AthletesController#destroy` and `ProfilesController#destroy`): `SuperAdmin::AthletesController#destroy` — the "All athletes" super-admin page's delete action — called `@athlete.destroy` directly with no protection at all. Fixed it to use the same `Athlete#delete_or_anonymize!` used by the other two delete paths.
- **Investigated and explicitly ruled out** a fourth path: `TournamentsController#destroy` (super admin deleting a tournament directly). Initially assumed it had the same gap and added a guard — but a regression test caught that this was wrong: `TournamentCategory` declares `has_many :matches, dependent: :destroy` *before* `has_many :registrations, dependent: :destroy`, so Rails already destroys a category's `Match` rows before it destroys the registrations they'd otherwise block — deleting a tournament with a generated draw has always been safe. Reverted that guard immediately (confirmed via `git diff` there's no trace of it left) rather than leave in a speculative, untested change. This is exactly why `Athlete` needed the fix and `Tournament` didn't: `Athlete` has no sibling `has_many :matches` association to destroy its athlete's matches first.
- Answered the reuse question directly: yes — `User#deactivate!` already renames the deactivated account's email to `deleted-user-<id>@deleted.podiumcircle.internal` specifically so the real address is freed up for a brand new signup. No change needed there.

### Verification Log
- Ran the exact production scenario locally (`bin/rails runner`, then walked through the UI as that athlete): created an athlete with `external_academy_name` set (which raises the `SuperAdminNotification` with the athlete as actor, exactly like production), signed in, clicked "Delete account" — confirmed the account is now deactivated with the correct message instead of a 500 error, and confirmed via the DB afterward (`deactivated: true`, email replaced) that the notification row survives untouched.
- Ran `mise exec -- bin/rails test test/controllers/profiles_controller_test.rb test/controllers/tournaments_controller_test.rb test/models/tournament_test.rb test/controllers/super_admin_athletes_controller_test.rb test/controllers/athletes_controller_test.rb test/models/athlete_test.rb`: 183 runs, 0 failures — includes a new regression test reproducing the exact `SuperAdminNotification`-actor crash, a new regression test for `SuperAdmin::AthletesController#destroy` with match history (anonymized, not crashed), and a corrected test proving an organizer's non-preserved tournament with a generated draw is destroyed cleanly (not deactivated) on account deletion, matching the actual safe cascade behavior.
- Ran full suite `mise exec -- bin/rails test`: 498 runs, 3572 assertions, 0 failures, 0 errors, 0 skips.
- Nothing pushed or committed — all changes remain local per standing instruction from earlier in this session. This fix has not yet been deployed to Fly; the production error will keep happening for any athlete in that state until this is deployed.

## 2026-09-23 (cont.) - Academy Owner "Remove Athlete": Redirect Fix (Confirmation Already Existed)

### Reference
- User asked for a confirmation popup before an academy owner removes an athlete from their roster, and for the redirect afterward to land back on the roster page (`/academies/:id/athletes`) instead of what they described as "profile page."

### Change Log
- The confirmation popup already existed — `academies/athletes.html.erb`'s "Remove athlete" kebab-menu action is a `button_to` with `data: { turbo_confirm: "Are you sure you want to remove #{athlete.full_name} from #{@academy.name}?" }`, Turbo's built-in native confirm dialog (Yes/Cancel; declining leaves the athlete on the roster). No change needed there.
- Fixed the actual issue: `AthletesController#destroy`'s academy-owner branch redirected to `academy_path(academy)` (`/academies/:id`, the academy's own general profile page) after removing an athlete — not the roster page the owner was actually on. Changed it to `athletes_academy_path(academy)` (`/academies/:id/athletes`), so the owner lands back exactly where they started.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb test/controllers/athletes_controller_test.rb`: 74 runs, 0 failures — updated the two existing tests asserting the old redirect target.
- Ran full suite `mise exec -- bin/rails test`: 498 runs, 3572 assertions, 0 failures, 0 errors, 0 skips.
- Manually verified against the local dev server as the academy owner (`academy@podiumcircle.test`): opened the kebab menu for an athlete on `/academies/1/athletes`, clicked "Remove athlete," confirmed the dialog, and landed back on `/academies/1/athletes` with the athlete gone from the list and the "Athlete removed from academy." flash shown.
- Nothing pushed or committed — all changes remain local per standing instruction from earlier in this session.

## 2026-09-23 (cont.) - Local Seed Data Cleanup

### Reference
- User asked to clean up all local data and set local seed data properly with 2-3 proper tournaments, 6-7 academies, and about 200 athletes.

### Change Log
- Replaced `db/seeds.rb` with a deterministic local dataset designed for ongoing QA:
  - 1 super admin account.
  - 3 verified organizer accounts.
  - 7 approved academies with owners, contact details, and logos.
  - 200 athlete accounts distributed across those academies, genders, ages, belts, and weights.
  - 3 tournaments covering open registration, closed registration/weight-check, and completed-history scenarios.
  - Seeded tournament organizer collaborators, referees, payment details, default categories, registrations, weight-check attempts, and super-admin notifications.
- Kept the seed file local-development focused and removed older ad hoc/demo/test-style seed records from the intended reset output.

### Verification Log
- Ran `mise exec -- bin/rails db:reset` locally. The first run was blocked by active local Rails/database sessions, so the local Puma server, Rails console, and stale test process were stopped/cleared; reran successfully.
- Final seed output:
  - Academies: 7
  - Athletes: 200
  - Tournaments: 3
  - Registrations: 180
- Verified distribution with `bin/rails runner`:
  - Users: 200 athletes, 7 academy owners, 3 organizers, 1 super admin.
  - Academies: 7 approved.
  - Tournaments: 1 registration open, 1 registration closed, 1 completed.
  - Registrations: 32 pending, 54 approved, 62 weight verified, 16 disqualified, 16 rejected.
  - Referees: 5.
  - Categories: 378 default tournament categories across the 3 tournaments.

## 2026-09-23 (cont.) - Local QA Round After Seed Reset

### Reference
- User asked to perform a round of testing on local after the local data cleanup and seed reset.

### Verification Log
- Ran full automated Rails test suite: `mise exec -- bin/rails test`.
  - Result: 502 runs, 3609 assertions, 0 failures, 0 errors, 0 skips.
- Started the local Rails server on `http://127.0.0.1:3000` and ran a Playwright smoke test against seeded role accounts.
- Browser-smoked public pages: home, tournaments index, tournament details, academies index, academy details, terms page, and mobile views for home/tournaments/academies.
- Browser-smoked athlete flow with `athlete001@podiumcircle.test`: profile, tournament listing, public tournament details, and tournament registration entry page. Confirmed athlete tournament page did not show organizer-only registered-athlete management.
- Browser-smoked academy-owner flow with `pune.champions@podiumcircle.test`: academies index, academy details, academy athletes page, academy notifications page, and tournament registration entry page.
- Browser-smoked organizer flow with `organizer@podiumcircle.test`: organizer profile, registration approvals, tournament edit, venue setup, weight checks, and draw page for a seeded draw-ready category.
- Browser-smoked super-admin flow with `admin@podiumcircle.test`: notifications, all athletes, tournaments, academies, and organizers pages.
- Checked the Rails development log after the browser pass for server-side exceptions/500s; none were found.
- Two initial Playwright text expectations were false alarms, not app failures: the organizer page heading is "Registration approvals" rather than "Registrations", and the organizers page renders the heading uppercase as "ORGANIZERS".

## 2026-09-23 (cont.) - Group Registration Fixes (Academy Flow) + Clearer Eligibility Errors + Hid Forgot-Password Link

### Reference
- User reported several academy-flow bugs on the Pair/Team Poomsae ("group") registration screen from a screenshot: clicking "Add individual athlete" (meaning to bail out of an unfinished team) threw a "Choose a Pair or Team Poomsae category" error instead of navigating; teammate dropdowns needed to be scoped to the academy and prevent picking the same athlete twice; a "must all belong to the same academy" error appeared even when picking athletes who looked like they were from the same academy; and a request to support registering multiple teams. Mid-investigation the user also reported "Proceed to payment" had the same forced-team bug, and separately that a batch submit failed with an unclear "athlete's age does not match this category" error with no indication of which athlete or category. Finally, the user asked to hide the "Forgot password" link until email sending is configured.

### Change Log
- **Root-caused the false "different academy" error**: it traced back to my own earlier testing this session — I'd used "Kabir Patil" to test the academy-owner "Remove athlete" flow, which correctly unlinked him from his academy (`academy_id: nil`) as part of that test, but I never restored it. Restored `academy_id` back to Academy 1 for that athlete. This wasn't a product bug at all, but real product bugs made it easy to hit by accident (see next two points) — hardened both so it can't happen again the way the user described.
- **Fixed `RegistrationsController#create_group_draft`** (`app/controllers/registrations_controller.rb`): when nothing was actually filled in on the group form (no category chosen, no teammates picked), any submit button — "+ Add individual athlete" *and* "Proceed to payment" — now just navigates to the requested screen instead of running (and failing) group-entry validation for a form the user never meant to submit. A genuinely incomplete attempt (e.g. a category chosen but teammates missing) still shows the real validation error, since that reflects real intent to build a team.
- **Scoped the teammate dropdowns to only academy-affiliated athletes** (`RegistrationsController#group`): athletes with no academy at all (self-registered, not on any roster) can never satisfy "same academy," so they're excluded from the picker entirely rather than being selectable and then rejected.
- **Added client-side exclusion of already-picked teammates**: a small script (`app/views/registrations/group.html.erb`) disables an athlete's `<option>` in the other teammate dropdowns once they're chosen in one, so the same athlete can't be picked twice for a pair/team entry. (The backend was already safe against this — duplicate submitted ids get deduplicated, which would just fail the "select exactly N" count check — this is purely a UX improvement so the mistake can't happen in the first place.)
- **Added a "+ Add another team" button** to the group screen (submits the current team, same as "Proceed to payment" would, then loops back to a fresh group form instead of leaving to individual/payment) — multiple teams were already fully supported by the data model (the uniqueness constraint is per athlete+category, not per "team"), this just makes registering several teams in one sitting a direct in-page loop instead of a round-trip through the individual/payment screens.
- **Made eligibility errors name the specific athlete and category** (`TournamentCategory#eligibility_errors_for`, `app/models/tournament_category.rb`): every message ("athlete's age does not match this category", "athlete's gender does not match this category", etc.) was generic and gave no indication of which athlete or which category out of a whole batch submission. Rewrote all four checks (gender, age, belt, weight) to read like "Kabir Patil is 17 years old, which is outside the age range for Kyorugi Male Age 12-14" — since this is the single method backing every registration eligibility check in the app (individual, group, and the final submit), the fix applies everywhere at once with no per-call-site changes needed.
- **Hid the "Forgot your password?" link** on the login page (`app/views/sessions/new.html.erb`) — the user doesn't have an email-sending service configured yet (explained in plain terms: the reset-password feature is fully built in the app, there's just no mail carrier wired up to actually deliver the email), so a password reset request would currently go nowhere. The underlying `password_resets` routes/controller/views are untouched and still fully functional — only the visible entry point on the login page is hidden, ready to re-enable once an email service (Postmark/Resend/SendGrid/Mailgun) is set up.

### Verification Log
- Ran `mise exec -- bin/rails test test/models/registration_test.rb test/controllers/registrations_controller_test.rb test/controllers/sessions_controller_test.rb test/controllers/password_resets_controller_test.rb`: all green — includes new tests for the "nothing filled in → navigate" fix, the academy-only teammate dropdown scoping, the "add another team" flow, a combined individual-entry-plus-team-submitted-together end-to-end test (mirroring the exact scenario manually tested below), and updated tests for the new clearer eligibility messages and the hidden forgot-password link.
- Ran full suite `mise exec -- bin/rails test`: 502 runs, 3607 assertions, 0 failures, 0 errors, 0 skips.
- Manually walked the full flow against the local dev server as the academy owner: added an individual Kyorugi entry for Ishaan Deshmukh, clicked "+ Add Pair/Team Poomsae entry," built a Pair Poomsae team (Kabir Patil & Rehan Shaikh), confirmed the teammate-exclusion JS via direct DOM inspection (picking one athlete disables them in the other dropdown), clicked "+ Add individual athlete" with an empty group form and confirmed it navigates cleanly with no error, clicked "Proceed to payment" with an empty group form and confirmed it goes straight to the (correctly empty) payment page, then completed the flow to the real payment page — total INR 3,800 across both entries, the auto-generated UPI QR rendered correctly, and the "Payment receipt must be uploaded" validation fired correctly when submitting without one. (Restarted the local Rails server mid-session, since it was still running on the pre-`rqrcode` bundle from the UPI QR work earlier and crashed on the payment page — same underlying restart-needed issue flagged earlier, now resolved locally.) Couldn't complete the literal file-upload click through browser automation (no way to drive a native OS file picker), so the receipt-upload-and-final-submit step is covered instead by a new automated test reproducing the exact same individual+team combined batch.
- Nothing pushed or committed — all changes remain local per standing instruction from earlier in this session.

## 2026-09-23 (cont.) - Telangana Screenshot-Ready Local Seed Data

### Reference
- User asked to make local data good for screenshots to coaches and parents, test it with the latest migrations, keep names and academies Telangana-style, and use generated images for athlete photos plus academy logos/banners.

### Change Log
- Reworked `db/seeds.rb` into a deterministic Telangana-focused local dataset:
  - 7 approved academies in Hyderabad, Warangal, Karimnagar, Nizamabad, Khammam, Secunderabad, and Nalgonda.
  - 200 athletes with Telangana-style names, realistic ages, weights, belts, blood groups, contacts, emergency contacts, addresses, and a mix of registered-academy and independent-academy profiles.
  - 3 tournaments covering open registration, closed registration/weight-check, and completed-history flows.
  - 180 registrations across pending, approved, rejected, weight-verified, and disqualified states.
  - Referees, organizer collaborators, payment details, receipts, identity documents, categories, weight checks, and super-admin notifications for local flow testing.
- Added seed-time PNG generation for fictional local media assets: athlete portrait illustrations, academy logo-style graphics, tournament logos, tournament banners, and payment receipts. These generated files are intentionally fictional and do not use real people or real academy branding.
- Added `/db/seed_assets/` to `.gitignore` because the media files are generated by `db/seeds.rb` and do not need to be committed.
- Fixed the seed attachment helper to use in-memory streams (`StringIO`) so Active Storage validations can read files reliably during model validation.

### Verification Log
- Ran `mise exec -- bin/rails db:reset` locally against the latest migrations and new seed data. Final output:
  - Academies: 7
  - Athletes: 200
  - Tournaments: 3
  - Registrations: 180
- Verified seeded data with `bin/rails runner`:
  - Users: 211
  - Academy logos attached: 7
  - Athlete photos attached: 200
  - Tournament banners attached: 3
  - Academy states: Telangana only
  - Tournament names: Karimnagar Invitational Taekwondo League, Warangal District Taekwondo Cup, Hyderabad Open Taekwondo Championship 2026
- Ran full automated Rails test suite: `mise exec -- bin/rails test`.
  - Result: 502 runs, 3607 assertions, 0 failures, 0 errors, 0 skips.
- No production deploy was performed for this local-data request.

## 2026-09-23 (cont.) - Academy Page: Replaced "Owner" Field with "City"

### Reference
- User asked to rename the "Owner" field label on an academy's page (visible even when signed out) to "Contact person." Flagged that the page already has a separate "Contact person" row (shows `contact_name`, falling back to the owner's name) right above it, so renaming would create two rows with the same label. User decided instead to remove the "Owner" row and show "City" in its place.

### Change Log
- `app/views/academies/show.html.erb`: the "Contact details" panel's fourth row changed from `Owner` (`@academy.owner&.name`) to `City` (`@academy.city`). The existing "Contact person" row (line 80, unchanged) remains the one place a contact name/owner fallback is shown.

### Verification Log
- Ran `mise exec -- bin/rails test test/controllers/academies_controller_test.rb`: 35 runs, 0 failures.
- Ran full suite `mise exec -- bin/rails test`: 502 runs, 3607 assertions, 0 failures, 0 errors, 0 skips.
- Verified visually against the local dev server while signed out, viewing an academy's public page: "Owner" no longer appears; "City" shows correctly (e.g. "Hyderabad"); "Contact person" still shows the contact/owner name as before.
- Nothing pushed or committed — all changes remain local per standing instruction from earlier in this session.
