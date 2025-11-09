ActiveRecord::Schema[7.1].define(version: 1) do
  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "reviews", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.string "status", default: "pending"
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_reviews_on_author_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content", null: false
    t.integer "review_id", null: false
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["review_id"], name: "index_comments_on_review_id"
  end
end

