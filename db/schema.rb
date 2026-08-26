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

ActiveRecord::Schema[8.1].define(version: 2026_08_26_094000) do
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

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "athletes", force: :cascade do |t|
    t.bigint "academy_id"
    t.text "address"
    t.string "association_id"
    t.string "belt"
    t.string "blood_group"
    t.string "city"
    t.string "contact_number"
    t.string "country", default: "India"
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "first_name", null: false
    t.string "gender", null: false
    t.string "government_id_document_type"
    t.string "last_name", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.decimal "weight", precision: 5, scale: 2
    t.index ["academy_id"], name: "index_athletes_on_academy_id"
    t.index ["user_id"], name: "index_athletes_on_user_id"
  end

  create_table "registration_action_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "from_status"
    t.bigint "registration_id", null: false
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_registration_action_logs_on_actor_id"
    t.index ["registration_id"], name: "index_registration_action_logs_on_registration_id"
  end

  create_table "registration_weight_checks", force: :cascade do |t|
    t.integer "attempt_number", null: false
    t.datetime "checked_at", null: false
    t.bigint "checked_by_id", null: false
    t.datetime "created_at", null: false
    t.boolean "passed", default: false, null: false
    t.bigint "registration_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 5, scale: 2, null: false
    t.index ["checked_by_id"], name: "index_registration_weight_checks_on_checked_by_id"
    t.index ["registration_id", "attempt_number"], name: "idx_on_registration_id_attempt_number_89262627f2", unique: true
    t.index ["registration_id"], name: "index_registration_weight_checks_on_registration_id"
    t.check_constraint "attempt_number >= 1 AND attempt_number <= 3", name: "registration_weight_checks_attempt_number_range"
    t.check_constraint "weight > 0::numeric", name: "registration_weight_checks_weight_positive"
  end

  create_table "registrations", force: :cascade do |t|
    t.bigint "athlete_id", null: false
    t.datetime "created_at", null: false
    t.decimal "fee_amount", precision: 10, scale: 2
    t.string "fee_currency"
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
    t.decimal "registration_fee", precision: 10, scale: 2
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight_max", precision: 5, scale: 2
    t.decimal "weight_min", precision: 5, scale: 2
    t.index ["tournament_id", "category_key"], name: "index_categories_unique_identity", unique: true
    t.index ["tournament_id"], name: "index_tournament_categories_on_tournament_id"
  end

  create_table "tournament_organizers", force: :cascade do |t|
    t.bigint "added_by_id"
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["added_by_id"], name: "index_tournament_organizers_on_added_by_id"
    t.index ["tournament_id", "user_id"], name: "index_tournament_organizers_on_tournament_id_and_user_id", unique: true
    t.index ["tournament_id"], name: "index_tournament_organizers_on_tournament_id"
    t.index ["user_id"], name: "index_tournament_organizers_on_user_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "banner_image_url"
    t.string "category_generation_method"
    t.string "city"
    t.text "competition_formats"
    t.datetime "created_at", null: false
    t.string "currency"
    t.text "description"
    t.text "eligibility_summary"
    t.date "end_date", null: false
    t.string "logo_url"
    t.string "name", null: false
    t.bigint "organizer_id", null: false
    t.string "organizing_organization"
    t.string "payment_account_name"
    t.string "payment_account_number"
    t.string "payment_bank_name"
    t.string "payment_ifsc"
    t.text "payment_instructions"
    t.string "primary_contact_email"
    t.string "primary_contact_name"
    t.string "primary_contact_phone"
    t.text "refund_policy"
    t.integer "registration_capacity"
    t.datetime "registration_closes_at"
    t.decimal "registration_fee", precision: 10, scale: 2
    t.datetime "registration_opens_at"
    t.text "required_documents"
    t.string "slug"
    t.date "start_date", null: false
    t.string "state"
    t.integer "status", default: 0, null: false
    t.string "time_zone"
    t.string "tournament_level"
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
    t.bigint "organizer_academy_id"
    t.datetime "organizer_approved_at"
    t.string "organizer_designation"
    t.datetime "organizer_rejected_at"
    t.bigint "organizer_reviewed_by_id"
    t.integer "organizer_status", default: 0, null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.string "profile_photo_url"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organizer_academy_id"], name: "index_users_on_organizer_academy_id"
    t.index ["organizer_reviewed_by_id"], name: "index_users_on_organizer_reviewed_by_id"
  end

  add_foreign_key "academies", "users", column: "owner_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "athletes", "academies"
  add_foreign_key "athletes", "users"
  add_foreign_key "registration_action_logs", "registrations"
  add_foreign_key "registration_action_logs", "users", column: "actor_id"
  add_foreign_key "registration_weight_checks", "registrations"
  add_foreign_key "registration_weight_checks", "users", column: "checked_by_id"
  add_foreign_key "registrations", "athletes"
  add_foreign_key "registrations", "tournament_categories"
  add_foreign_key "registrations", "tournaments"
  add_foreign_key "tournament_categories", "tournaments"
  add_foreign_key "tournament_organizers", "tournaments"
  add_foreign_key "tournament_organizers", "users"
  add_foreign_key "tournament_organizers", "users", column: "added_by_id"
  add_foreign_key "tournaments", "users", column: "organizer_id"
  add_foreign_key "users", "academies", column: "organizer_academy_id"
  add_foreign_key "users", "users", column: "organizer_reviewed_by_id"
end
