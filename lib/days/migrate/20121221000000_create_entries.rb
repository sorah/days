class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.string   :title,       null: false
      t.text     :body,        null: false
      t.text     :rendered,    null: false
      t.string   :slug,        null: false, unique: true
      t.integer  :user_id
      t.datetime :published_at

      t.timestamps
    end

    add_index :entries, :published_at
    add_index :entries, :user_id
    add_index :entries, :slug
  end
end
