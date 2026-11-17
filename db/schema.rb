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

ActiveRecord::Schema[8.1].define(version: 2026_11_17_210740) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "street", limit: 160, null: false
    t.string "number", limit: 10, null: false
    t.string "district", limit: 80, null: false
    t.string "zip_code", limit: 9, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", limit: 60, null: false
    t.string "slug", limit: 60, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "contact_logs", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "courier_id", null: false
    t.string "channel", limit: 10, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["courier_id"], name: "index_contact_logs_on_courier_id"
    t.index ["order_id"], name: "index_contact_logs_on_order_id"
  end

  create_table "coupons", force: :cascade do |t|
    t.string "code", limit: 30, null: false
    t.string "description", limit: 120, default: "", null: false
    t.integer "percentage", null: false
    t.date "valid_until", null: false
    t.integer "usage_limit"
    t.integer "uses_count", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_coupons_on_code", unique: true
    t.check_constraint "percentage >= 1 AND percentage <= 90", name: "coupons_percentage_range"
  end

  create_table "cupcake_photos", force: :cascade do |t|
    t.bigint "cupcake_id", null: false
    t.string "content_type", null: false
    t.binary "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cupcake_id"], name: "index_cupcake_photos_on_cupcake_id", unique: true
  end

  create_table "cupcakes", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "name", limit: 80, null: false
    t.text "description", null: false
    t.text "ingredients", default: "", null: false
    t.decimal "price", precision: 8, scale: 2, null: false
    t.integer "stock", default: 0, null: false
    t.integer "min_stock", default: 5, null: false
    t.integer "calories"
    t.decimal "fat_grams", precision: 5, scale: 1
    t.decimal "sugar_grams", precision: 5, scale: 1
    t.string "allergens", limit: 200, default: "", null: false
    t.string "color", limit: 7, default: "#f9a8d4", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "photo_updated_at"
    t.index ["category_id"], name: "index_cupcakes_on_category_id"
    t.check_constraint "price > 0::numeric", name: "cupcakes_price_positive"
    t.check_constraint "stock >= 0", name: "cupcakes_stock_not_negative"
  end

  create_table "delivery_zones", force: :cascade do |t|
    t.string "name", limit: 80, null: false
    t.decimal "fee", precision: 6, scale: 2, null: false
    t.integer "eta_minutes", default: 45, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_delivery_zones_on_name", unique: true
    t.check_constraint "fee >= 0::numeric", name: "delivery_zones_fee_not_negative"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "cupcake_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cupcake_id"], name: "index_favorites_on_cupcake_id"
    t.index ["user_id", "cupcake_id"], name: "index_favorites_on_user_id_and_cupcake_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "order_id"
    t.string "message", limit: 255, null: false
    t.boolean "read", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_notifications_on_order_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "cupcake_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 8, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cupcake_id"], name: "index_order_items_on_cupcake_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.check_constraint "quantity > 0", name: "order_items_quantity_positive"
  end

  create_table "orders", force: :cascade do |t|
    t.string "code", limit: 12, null: false
    t.bigint "customer_id", null: false
    t.bigint "courier_id"
    t.bigint "coupon_id"
    t.bigint "delivery_zone_id"
    t.string "status", limit: 30, default: "paid", null: false
    t.string "fulfillment", limit: 10, null: false
    t.string "delivery_address", limit: 255
    t.string "payment_method", limit: 10, null: false
    t.string "card_last4", limit: 4
    t.string "pix_code", limit: 255
    t.decimal "subtotal", precision: 10, scale: 2, null: false
    t.decimal "discount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "shipping_fee", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_orders_on_code", unique: true
    t.index ["coupon_id"], name: "index_orders_on_coupon_id"
    t.index ["courier_id"], name: "index_orders_on_courier_id"
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["delivery_zone_id"], name: "index_orders_on_delivery_zone_id"
    t.index ["status"], name: "index_orders_on_status"
    t.check_constraint "total >= 0::numeric", name: "orders_total_not_negative"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "order_id", null: false
    t.bigint "cupcake_id", null: false
    t.integer "rating", null: false
    t.integer "delivery_rating", null: false
    t.text "comment", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cupcake_id"], name: "index_reviews_on_cupcake_id"
    t.index ["order_id", "cupcake_id"], name: "index_reviews_on_order_id_and_cupcake_id", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
    t.check_constraint "delivery_rating >= 1 AND delivery_rating <= 5", name: "reviews_delivery_rating_range"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "reviews_rating_range"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", limit: 120, null: false
    t.string "email", limit: 160, null: false
    t.string "phone", limit: 20
    t.string "password_digest", null: false
    t.string "role", limit: 20, default: "customer", null: false
    t.boolean "notifications_enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.check_constraint "role::text = ANY (ARRAY['customer'::character varying, 'admin'::character varying, 'courier'::character varying]::text[])", name: "users_role_valid"
  end

  add_foreign_key "addresses", "users"
  add_foreign_key "contact_logs", "orders"
  add_foreign_key "contact_logs", "users", column: "courier_id"
  add_foreign_key "cupcake_photos", "cupcakes"
  add_foreign_key "cupcakes", "categories"
  add_foreign_key "favorites", "cupcakes"
  add_foreign_key "favorites", "users"
  add_foreign_key "notifications", "orders"
  add_foreign_key "notifications", "users"
  add_foreign_key "order_items", "cupcakes"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "coupons"
  add_foreign_key "orders", "delivery_zones"
  add_foreign_key "orders", "users", column: "courier_id"
  add_foreign_key "orders", "users", column: "customer_id"
  add_foreign_key "reviews", "cupcakes"
  add_foreign_key "reviews", "orders"
  add_foreign_key "reviews", "users"
end
