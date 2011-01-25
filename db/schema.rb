# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091004220935) do

  create_table "conf_units", :force => true do |t|
    t.integer  "parent_id"
    t.integer  "root_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "broken",     :default => false
    t.text     "properties"
    t.string   "kind",       :default => "default", :null => false
  end

  create_table "posts_tree", :id => false, :force => true do |t|
    t.integer "owner_id",                 :null => false
    t.integer "parent_id",                :null => false
    t.integer "level",     :default => 0, :null => false
  end

  add_index "posts_tree", ["owner_id", "parent_id"], :name => "index_posts_tree_on_owner_id_and_parent_id", :unique => true

end
