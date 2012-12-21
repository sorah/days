class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.string :title
      t.text :body
      t.text :rendered
      t.datetime :published_at
      t.integer :user_id
    end

    add_index :entries, :published_at
    add_index :entries, :user_id
  end
end
