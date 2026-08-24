# Sports Hub

A Rails-based platform for athletes, academies, tournaments, registrations, and competition operations.

## Current MVP flow

**User → Athlete → Academy → Tournament → Category → Registration → Organizer Approval**

## Long-lived implementation log

Maintain [`PROGRESS.md`](PROGRESS.md) for every product decision, code change, validation rule, and verification result. This file is intended to remain useful as a multi-year project reference.

## Tech stack
- Ruby 3.3.8
- Rails 8.1.x
- PostgreSQL
- Hotwire / Turbo
- Plain CSS
- Minitest

## Local setup

```bash
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails server
```

Open `http://localhost:3000`.

## Docker PostgreSQL

```bash
docker compose up -d db
```

Then export:

```bash
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/taekwondo_hub_development
```

## MVP roadmap
1. Authentication
2. Athlete profiles
3. Academy management
4. Tournament creation
5. Category management
6. Athlete registration
7. Organizer approval
8. Match/bracket management
9. Fight results
10. Medal tally

## Demo credentials

After seeding, use these local demo accounts:

- Super admin: `admin@example.com` / `password123`
- Academy owner: `academy-owner@example.com` / `password123`
- Organizer: `organizer@example.com` / `password123`
- General user: `parent@example.com` / `password123`

After seeding, try this flow:

1. Open `/athletes` and create/edit an athlete.
2. Open `/academies` and add/select an academy.
3. Open `/tournaments` and choose a seeded tournament.
4. Submit a registration for an athlete and category.
5. Open `/organizer/registrations` and approve or reject it.
