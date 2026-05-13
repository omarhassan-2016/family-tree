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

ActiveRecord::Schema[7.2].define(version: 2026_05_13_050102) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "families", force: :cascade do |t|
    t.string "gedcom_id"
    t.date "marriage_date"
    t.string "marriage_place"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gedcom_id"], name: "index_families_on_gedcom_id", unique: true, where: "(gedcom_id IS NOT NULL)"
  end

  create_table "family_members", force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "family_id", null: false
    t.integer "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_family_members_on_family_id"
    t.index ["person_id", "family_id", "role"], name: "index_family_members_uniqueness", unique: true
    t.index ["person_id"], name: "index_family_members_on_person_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "gedcom_id"
    t.string "first_name", null: false
    t.string "last_name"
    t.string "maiden_name"
    t.string "suffix"
    t.integer "gender", default: 0
    t.date "birth_date"
    t.string "birth_place"
    t.date "death_date"
    t.string "death_place"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["first_name"], name: "index_people_on_first_name"
    t.index ["first_name"], name: "index_people_on_first_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["gedcom_id"], name: "index_people_on_gedcom_id", unique: true, where: "(gedcom_id IS NOT NULL)"
    t.index ["last_name"], name: "index_people_on_last_name"
    t.index ["last_name"], name: "index_people_on_last_name_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  add_foreign_key "family_members", "families"
  add_foreign_key "family_members", "people"
end
