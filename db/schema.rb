# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_09_06_190755) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "authorships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "publication_id", null: false
    t.integer "author_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publication_id"], name: "index_authorships_on_publication_id"
    t.index ["user_id"], name: "index_authorships_on_user_id"
  end

  create_table "committee_memberships", force: :cascade do |t|
    t.integer "etd_id", null: false
    t.integer "user_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["etd_id"], name: "index_committee_memberships_on_etd_id"
    t.index ["user_id"], name: "index_committee_memberships_on_user_id"
  end

  create_table "contract_imports", force: :cascade do |t|
    t.integer "contract_id", null: false
    t.integer "activity_insight_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_insight_id"], name: "index_contract_imports_on_activity_insight_id", unique: true
    t.index ["contract_id"], name: "index_contract_imports_on_contract_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.text "title", null: false
    t.string "contract_type"
    t.text "sponsor", null: false
    t.text "status", null: false
    t.integer "amount", null: false
    t.integer "ospkey", null: false
    t.date "award_start_on", null: false
    t.date "award_end_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ospkey"], name: "index_contracts_on_ospkey", unique: true
  end

  create_table "contributors", force: :cascade do |t|
    t.integer "publication_id", null: false
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publication_id"], name: "index_contributors_on_publication_id"
  end

  create_table "duplicate_publication_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "etds", force: :cascade do |t|
    t.text "title", null: false
    t.string "author_first_name", null: false
    t.string "author_last_name", null: false
    t.string "author_middle_name"
    t.string "webaccess_id", null: false
    t.integer "year", null: false
    t.text "url", null: false
    t.string "submission_type", null: false
    t.string "external_identifier", null: false
    t.string "access_level", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_identifier"], name: "index_etds_on_external_identifier"
    t.index ["webaccess_id"], name: "index_etds_on_webaccess_id"
  end

  create_table "publication_imports", force: :cascade do |t|
    t.integer "publication_id", null: false
    t.string "source", null: false
    t.string "source_identifier", null: false
    t.datetime "source_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publication_id"], name: "index_publication_imports_on_publication_id"
    t.index ["source_identifier", "source"], name: "index_publication_imports_on_source_identifier_and_source", unique: true
  end

  create_table "publication_taggings", force: :cascade do |t|
    t.integer "publication_id", null: false
    t.integer "tag_id", null: false
    t.float "rank"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publication_id"], name: "index_publication_taggings_on_publication_id"
    t.index ["tag_id"], name: "index_publication_taggings_on_tag_id"
  end

  create_table "publications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "title", null: false
    t.string "publication_type", null: false
    t.text "journal_title"
    t.text "publisher"
    t.text "secondary_title"
    t.string "status"
    t.string "volume"
    t.string "issue"
    t.string "edition"
    t.string "page_range"
    t.text "url"
    t.string "isbn"
    t.string "issn"
    t.string "doi"
    t.text "abstract"
    t.boolean "authors_et_al"
    t.date "published_on"
    t.integer "citation_count"
    t.integer "duplicate_publication_group_id"
    t.datetime "updated_by_user_at"
    t.boolean "visible", default: false
    t.index ["duplicate_publication_group_id"], name: "index_publications_on_duplicate_publication_group_id"
    t.index ["issue"], name: "index_publications_on_issue"
    t.index ["volume"], name: "index_publications_on_volume"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name"
  end

  create_table "user_contracts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "contract_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id"], name: "index_user_contracts_on_contract_id"
    t.index ["user_id"], name: "index_user_contracts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "activity_insight_identifier"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_admin", default: false
    t.string "webaccess_id", null: false
    t.string "pure_uuid"
    t.string "penn_state_identifier"
    t.datetime "updated_by_user_at"
    t.index ["activity_insight_identifier"], name: "index_users_on_activity_insight_identifier", unique: true
    t.index ["penn_state_identifier"], name: "index_users_on_penn_state_identifier", unique: true
    t.index ["pure_uuid"], name: "index_users_on_pure_uuid", unique: true
    t.index ["webaccess_id"], name: "index_users_on_webaccess_id", unique: true
  end

  add_foreign_key "authorships", "publications", on_delete: :cascade
  add_foreign_key "authorships", "users", on_delete: :cascade
  add_foreign_key "committee_memberships", "etds", on_delete: :cascade
  add_foreign_key "committee_memberships", "users", on_delete: :cascade
  add_foreign_key "contract_imports", "contracts", on_delete: :cascade
  add_foreign_key "contributors", "publications", on_delete: :cascade
  add_foreign_key "publication_imports", "publications", name: "publication_imports_publication_id_fk"
  add_foreign_key "publication_taggings", "publications", on_delete: :cascade
  add_foreign_key "publication_taggings", "tags", on_delete: :cascade
  add_foreign_key "publications", "duplicate_publication_groups", name: "publications_duplicate_publication_group_id_fk"
  add_foreign_key "user_contracts", "contracts", on_delete: :cascade
  add_foreign_key "user_contracts", "users", on_delete: :cascade
end
