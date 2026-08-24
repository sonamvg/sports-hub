# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_24_000100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "academies", force: :cascade do |t|
    t.string "city", null: false
    t.string "contact_name"
    t.string "country", default: "India"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.bigint "owner_id"
    t.string "phone"
    t.string "registration_number"
    t.text "rejection_reason"
    t.datetime "reviewed_at"
    t.string "state"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_academies_on_owner_id"
  end

  create_table "athletes", force: :cascade do |t|
    t.bigint "academy_id"
    t.string "association_id"
    t.string "belt"
    t.string "city"
    t.string "country", default: "India"
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.string "first_name", null: false
    t.string "gender", null: false
    t.string "last_name", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.decimal "weight", precision: 5, scale: 2
    t.index ["academy_id"], name: "index_athletes_on_academy_id"
    t.index ["user_id"], name: "index_athletes_on_user_id"
  end

  create_table "registrations", force: :cascade do |t|
    t.bigint "athlete_id", null: false
    t.datetime "created_at", null: false
    t.decimal "registered_weight", precision: 5, scale: 2
    t.string "registration_number"
    t.integer "status", default: 0, null: false
    t.bigint "tournament_category_id", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["athlete_id"], name: "index_registrations_on_athlete_id"
    t.index ["tournament_category_id"], name: "index_registrations_on_tournament_category_id"
    t.index ["tournament_id", "athlete_id", "tournament_category_id"], name: "index_registrations_unique_entry", unique: true
    t.index ["tournament_id"], name: "index_registrations_on_tournament_id"
  end

  create_table "tournament_categories", force: :cascade do |t|
    t.integer "age_max"
    t.integer "age_min"
    t.string "belt_max"
    t.string "belt_min"
    t.string "category_key", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "gender"
    t.string "name", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight_max", precision: 5, scale: 2
    t.decimal "weight_min", precision: 5, scale: 2
    t.index ["tournament_id", "category_key"], name: "index_categories_unique_identity", unique: true
    t.index ["tournament_id"], name: "index_tournament_categories_on_tournament_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "city"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date", null: false
    t.string "logo_url"
    t.string "name", null: false
    t.bigint "organizer_id", null: false
    t.datetime "registration_closes_at"
    t.datetime "registration_opens_at"
    t.string "slug"
    t.date "start_date", null: false
    t.string "state"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "venue"
    t.string "website_url"
    t.index ["organizer_id"], name: "index_tournaments_on_organizer_id"
    t.index ["slug"], name: "index_tournaments_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "academies", "users", column: "owner_id"
  add_foreign_key "athletes", "academies"
  add_foreign_key "athletes", "users"
  add_foreign_key "registrations", "athletes"
  add_foreign_key "registrations", "tournament_categories"
  add_foreign_key "registrations", "tournaments"
  add_foreign_key "tournament_categories", "tournaments"
  add_foreign_key "tournaments", "users", column: "organizer_id"
end
