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

ActiveRecord::Schema.define(version: 20150925121523) do

  create_table "j_filters", force: true do |t|
    t.string   "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "j_filters", ["body"], name: "index_j_filters_on_body"
  add_index "j_filters", ["updated_at"], name: "index_j_filters_on_updated_at"

  create_table "last_reports", force: true do |t|
    t.string   "issue"
    t.integer  "total"
    t.integer  "passed"
    t.integer  "failed"
    t.integer  "inprogress"
    t.integer  "p_executed"
    t.integer  "p_passed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "options", force: true do |t|
    t.string   "key"
    t.string   "option"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "test_preparations", force: true do |t|
    t.string   "issue"
    t.integer  "tc_plan"
    t.datetime "tc_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "complete_date"
  end

end
