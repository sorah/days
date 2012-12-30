class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.string :title
      t.text :body
      t.text :rendered
      t.datetime :published_at
      t.integer :user_id
      t.string :slug

      t.timestamps
    end

    add_index :entries, :published_at
    add_index :entries, :user_id
    add_index :entries, :slug
  end
end
