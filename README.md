# PodiumCircle

A Rails-based platform for athletes, academies, tournaments, registrations, and competition operations.

## Current MVP flow

**User → Athlete → Academy → Tournament → Category → Registration → Organizer Approval**

## Long-lived implementation log

Maintain [`PROGRESS.md`](PROGRESS.md) for every product decision, code change, validation rule, and verification result. This file is intended to remain useful as a multi-year project reference.

## Author
Sonam

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

## Local seed credentials

After seeding, use these local accounts:

- Super admin: `admin@podiumcircle.test` / `password123`
- Academy owner: `academy@podiumcircle.test` / `password123`
- Organizer: `organizer@podiumcircle.test` / `password123`
- Athlete: `athlete@podiumcircle.test` / `password123`

## Production domain

The purchased domain is `podiumcircle.com`. In production, set:

```bash
APP_HOST=podiumcircle.com
MAILER_FROM=no-reply@podiumcircle.com
```

After seeding, try this flow:

1. Open `/athletes` and create/edit an athlete.
2. Open `/academies` and add/select an academy.
3. Open `/tournaments` and choose a seeded tournament.
4. Submit a registration for an athlete and category.
5. Open `/organizer/registrations` and approve or reject it.
