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

ActiveRecord::Schema[7.1].define(version: 2026_05_06_172455) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "geolocations", force: :cascade do |t|
    t.string "lookup_key", null: false
    t.string "ip"
    t.text "url"
    t.string "country_name"
    t.string "country_code", limit: 2
    t.string "region_name"
    t.string "region_code"
    t.string "city"
    t.string "zip"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "provider", default: "ipstack", null: false
    t.jsonb "provider_response", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((lookup_key)::text)", name: "index_geolocations_on_lower_lookup_key", unique: true
    t.index ["ip"], name: "index_geolocations_on_ip"
    t.index ["url"], name: "index_geolocations_on_url"
    t.check_constraint "ip IS NOT NULL OR url IS NOT NULL", name: "ip_or_url_present"
    t.check_constraint "latitude IS NULL OR latitude >= '-90'::integer::numeric AND latitude <= 90::numeric", name: "latitude_range"
    t.check_constraint "longitude IS NULL OR longitude >= '-180'::integer::numeric AND longitude <= 180::numeric", name: "longitude_range"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
