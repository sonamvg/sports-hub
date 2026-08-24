# Sports Hub Progress Log

This file is the long-lived implementation journal for Sports Hub. Keep it current for every code change, product decision, validation rule, test run, and known gap so future maintainers can reconstruct why the app behaves the way it does.

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
