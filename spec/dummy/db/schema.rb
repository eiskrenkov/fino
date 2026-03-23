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

ActiveRecord::Schema[8.1].define(version: 2026_03_23_211731) do
  create_table "fino_ab_testing_conversions", force: :cascade do |t|
    t.datetime "converted_at", null: false
    t.datetime "created_at", null: false
    t.string "scope", null: false
    t.string "setting_key", null: false
    t.datetime "updated_at", null: false
    t.string "variant_id", null: false
    t.index ["setting_key", "variant_id", "scope"], name: "idx_fino_conversions_unique", unique: true
    t.index ["setting_key", "variant_id"], name: "idx_fino_conversions_lookup"
  end

  create_table "fino_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_fino_settings_on_key", unique: true
  end
end
