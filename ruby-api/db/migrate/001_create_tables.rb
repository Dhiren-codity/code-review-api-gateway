class CreateTables < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name
      t.timestamps
    end

    add_index :users, :email, unique: true

    create_table :reviews do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :status, default: "pending"
      t.references :author, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :comments do |t|
      t.text :content, null: false
      t.references :review, null: false, foreign_key: true
      t.references :author, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end

