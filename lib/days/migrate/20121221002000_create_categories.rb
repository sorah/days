class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :name
    end

    create_table :categories_entries do |t|
      t.integer :category_id
      t.integer :entry_id
    end

    add_index :categories, :name

    add_index :categories_entries, :entry_id
    add_index :categories_entries, :category_id
  end
end
