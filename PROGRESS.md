# Sports Hub Progress Log

This file is the long-lived implementation journal for Sports Hub. Keep it current for every code change, product decision, validation rule, test run, and known gap so future maintainers can reconstruct why the app behaves the way it does.

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
