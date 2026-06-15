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

ActiveRecord::Schema[8.1].define(version: 2026_06_15_200720) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "availabilities", force: :cascade do |t|
    t.date "blocked_date", null: false
    t.datetime "created_at", null: false
    t.string "reason"
    t.bigint "room_id", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id", "blocked_date"], name: "index_availabilities_on_room_id_and_blocked_date", unique: true
    t.index ["room_id"], name: "index_availabilities_on_room_id"
  end

  create_table "booking_rooms", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.decimal "rate_per_night", precision: 10, scale: 2
    t.bigint "room_id", null: false
    t.bigint "room_type_id", null: false
    t.decimal "total_amount", precision: 12, scale: 2
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_booking_rooms_on_booking_id"
    t.index ["room_id"], name: "index_booking_rooms_on_room_id"
    t.index ["room_type_id"], name: "index_booking_rooms_on_room_type_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.date "check_in_date", null: false
    t.date "check_out_date", null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.bigint "guest_id", null: false
    t.integer "num_adults", default: 1
    t.integer "num_children", default: 0
    t.decimal "paid_amount", precision: 12, scale: 2, default: "0.0"
    t.string "payment_method"
    t.string "payment_status", default: "unpaid"
    t.text "special_requests"
    t.string "status", default: "pending"
    t.string "stripe_payment_intent_id"
    t.decimal "total_amount", precision: 12, scale: 2
    t.datetime "updated_at", null: false
    t.index ["check_in_date"], name: "index_bookings_on_check_in_date"
    t.index ["check_out_date"], name: "index_bookings_on_check_out_date"
    t.index ["guest_id"], name: "index_bookings_on_guest_id"
    t.index ["status", "check_in_date"], name: "index_bookings_on_status_and_check_in_date"
    t.index ["status"], name: "index_bookings_on_status"
  end

  create_table "contact_inquiries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "message"
    t.string "name", null: false
    t.string "phone"
    t.datetime "replied_at"
    t.string "status", default: "new"
    t.string "subject"
    t.datetime "updated_at", null: false
  end

  create_table "dining_reservations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.integer "number_of_guests"
    t.string "phone"
    t.date "reservation_date"
    t.integer "reservation_time"
    t.text "special_requests"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["reservation_date"], name: "index_dining_reservations_on_reservation_date"
    t.index ["status", "reservation_date"], name: "index_dining_reservations_on_status_and_reservation_date"
    t.index ["status"], name: "index_dining_reservations_on_status"
  end

  create_table "facilities", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon_name"
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true
    t.index ["category", "visible"], name: "index_facilities_on_category_and_visible"
    t.index ["category"], name: "index_facilities_on_category"
    t.index ["visible"], name: "index_facilities_on_visible"
  end

  create_table "gallery_albums", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true
  end

  create_table "gallery_images", force: :cascade do |t|
    t.string "caption"
    t.datetime "created_at", null: false
    t.bigint "gallery_album_id", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["gallery_album_id"], name: "index_gallery_images_on_gallery_album_id"
  end

  create_table "guests", force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "nationality"
    t.string "nid_or_passport"
    t.string "password_digest"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_guests_on_email", unique: true
  end

  create_table "menu_items", force: :cascade do |t|
    t.boolean "available"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "position"
    t.decimal "price"
    t.datetime "updated_at", null: false
    t.index ["available"], name: "index_menu_items_on_available"
    t.index ["category", "available"], name: "index_menu_items_on_category_and_available"
    t.index ["category"], name: "index_menu_items_on_category"
  end

  create_table "rates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_of_week"
    t.date "end_date", null: false
    t.string "name", null: false
    t.decimal "price_per_night", precision: 10, scale: 2, null: false
    t.integer "priority", default: 0
    t.bigint "room_type_id", null: false
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.index ["room_type_id"], name: "index_rates_on_room_type_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.boolean "approved", default: false
    t.text "body"
    t.bigint "booking_id", null: false
    t.integer "cleanliness_rating"
    t.datetime "created_at", null: false
    t.bigint "guest_id", null: false
    t.integer "rating", null: false
    t.integer "service_rating"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "value_rating"
    t.index ["approved"], name: "index_reviews_on_approved"
    t.index ["booking_id"], name: "index_reviews_on_booking_id"
    t.index ["created_at"], name: "index_reviews_on_created_at"
    t.index ["guest_id"], name: "index_reviews_on_guest_id"
  end

  create_table "room_types", force: :cascade do |t|
    t.jsonb "amenities", default: {}
    t.decimal "base_price_per_night", precision: 10, scale: 2
    t.string "bed_type"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "max_occupancy", null: false
    t.string "name", null: false
    t.integer "size_sqm"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_room_types_on_slug", unique: true
  end

  create_table "rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "floor"
    t.text "notes"
    t.string "room_number", null: false
    t.bigint "room_type_id", null: false
    t.string "status", default: "available", null: false
    t.datetime "updated_at", null: false
    t.index ["room_number"], name: "index_rooms_on_room_number", unique: true
    t.index ["room_type_id"], name: "index_rooms_on_room_type_id"
    t.index ["status"], name: "index_rooms_on_status"
  end

  create_table "settings", force: :cascade do |t|
    t.text "description"
    t.string "key", null: false
    t.text "value"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "availabilities", "rooms"
  add_foreign_key "booking_rooms", "bookings"
  add_foreign_key "booking_rooms", "room_types"
  add_foreign_key "booking_rooms", "rooms"
  add_foreign_key "bookings", "guests"
  add_foreign_key "gallery_images", "gallery_albums"
  add_foreign_key "rates", "room_types"
  add_foreign_key "reviews", "bookings"
  add_foreign_key "reviews", "guests"
  add_foreign_key "rooms", "room_types"
end
