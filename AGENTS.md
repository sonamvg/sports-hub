# Sports Hub Codex Instructions

Sports Hub is a Ruby on Rails tournament-management platform.

## Stack
- Ruby on Rails 8.1
- PostgreSQL
- Hotwire / Turbo
- Plain CSS
- Rails built-in authentication direction
- Minitest

## Product flow
User → Athlete → Academy → Tournament → Category → Registration → Organizer Approval

## Engineering rules
- Prefer Rails conventions over custom architecture.
- Keep controllers thin.
- Put business rules in models or small service objects when needed.
- Do not add React, Vue, or a separate API unless explicitly requested.
- Avoid unnecessary gems.
- Add tests for new business rules.
- Do not change unrelated files.
- Use database constraints for important invariants.
- Scope tournament data carefully.
- Keep the first MVP simple.
- Record every code change, product decision, validation change, and verification result in `PROGRESS.md`.

## Initial roles
- admin
- organizer
- coach
- parent
- athlete

## First milestone
- Public homepage
- User model
- Athlete profile
- Academy profile
- Tournament
- Tournament category
- Registration
- Organizer registration approval
