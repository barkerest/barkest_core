# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160701005706) do

  create_table "access_group_group_members", force: :cascade do |t|
    t.integer "group_id",  null: false
    t.integer "member_id", null: false
  end

  add_index "access_group_group_members", ["group_id", "member_id"], name: "unique_access_group_group_members", unique: true
  add_index "access_group_group_members", ["group_id"], name: "index_access_group_group_members_on_group_id"
  add_index "access_group_group_members", ["member_id"], name: "index_access_group_group_members_on_member_id"

  create_table "access_group_user_members", force: :cascade do |t|
    t.integer "group_id",  null: false
    t.integer "member_id", null: false
  end

  add_index "access_group_user_members", ["group_id", "member_id"], name: "unique_access_group_user_members", unique: true
  add_index "access_group_user_members", ["group_id"], name: "index_access_group_user_members_on_group_id"
  add_index "access_group_user_members", ["member_id"], name: "index_access_group_user_members_on_member_id"

  create_table "access_groups", force: :cascade do |t|
    t.string   "name",       limit: 100, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "access_groups", ["name"], name: "unique_access_groups", unique: true

  create_table "ldap_access_groups", force: :cascade do |t|
    t.integer  "group_id",               null: false
    t.string   "name",       limit: 200, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "ldap_access_groups", ["group_id", "name"], name: "unique_ldap_access_groups", unique: true

  create_table "user_login_histories", force: :cascade do |t|
    t.integer  "user_id",                null: false
    t.string   "ip_address", limit: 64,  null: false
    t.boolean  "successful"
    t.string   "message",    limit: 200
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "user_login_histories", ["user_id"], name: "index_user_login_histories_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "name",              limit: 100,                 null: false
    t.string   "email",             limit: 255,                 null: false
    t.boolean  "ldap",                          default: false
    t.boolean  "activated",                     default: false
    t.boolean  "enabled",                       default: true
    t.boolean  "system_admin",                  default: false
    t.string   "activation_digest"
    t.string   "password_digest"
    t.string   "remember_digest"
    t.string   "reset_digest"
    t.datetime "activated_at"
    t.datetime "reset_sent_at"
    t.integer  "disabled_by_id"
    t.datetime "disabled_at"
    t.string   "disabled_reason",   limit: 200
    t.datetime "last_login"
    t.string   "last_ip",           limit: 64
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
  end

  add_index "users", ["email"], name: "unique_users", unique: true

end
