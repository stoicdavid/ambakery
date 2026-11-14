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

ActiveRecord::Schema[8.1].define(version: 2026_11_14_050442) do
  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "wa_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone"], name: "index_customers_on_phone", unique: true
    t.index ["wa_id"], name: "index_customers_on_wa_id", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_variant_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_variant_id"], name: "index_order_items_on_product_variant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.string "status", default: "draft", null: false
    t.string "channel", default: "whatsapp", null: false
    t.string "fulfillment", default: "pickup", null: false
    t.date "scheduled_on"
    t.string "time_slot"
    t.string "string"
    t.text "delivery_address"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.text "notes"
    t.integer "total_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["scheduled_on", "status"], name: "index_orders_on_scheduled_on_and_status"
  end

  create_table "product_variants", force: :cascade do |t|
    t.integer "product_id", null: false
    t.string "name", null: false
    t.integer "price_cents", null: false
    t.boolean "active", default: true
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_variants_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "category", null: false
    t.text "description"
    t.integer "price_cents", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.integer "daily_capacity"
    t.integer "lead_time_days", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category", "active"], name: "index_products_on_category_and_active"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "whatsapp_conversations", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.string "state", default: "idle", null: false
    t.json "context", default: {}, null: false
    t.datetime "last_inbound_at"
    t.integer "draft_order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_whatsapp_conversations_on_customer_id", unique: true
    t.index ["draft_order_id"], name: "index_whatsapp_conversations_on_draft_order_id"
  end

  create_table "whatsapp_messages", force: :cascade do |t|
    t.integer "whatsapp_conversation_id", null: false
    t.string "wamid"
    t.string "direction", null: false
    t.string "message_type"
    t.text "body"
    t.json "payload", default: {}, null: false
    t.string "status"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wamid"], name: "index_whatsapp_messages_on_wamid", unique: true
    t.index ["whatsapp_conversation_id", "created_at"], name: "idx_on_whatsapp_conversation_id_created_at_858d582181"
    t.index ["whatsapp_conversation_id"], name: "index_whatsapp_messages_on_whatsapp_conversation_id"
  end

  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_variants"
  add_foreign_key "orders", "customers"
  add_foreign_key "product_variants", "products"
  add_foreign_key "sessions", "users"
  add_foreign_key "whatsapp_conversations", "customers"
  add_foreign_key "whatsapp_conversations", "orders", column: "draft_order_id"
  add_foreign_key "whatsapp_messages", "whatsapp_conversations"
end
