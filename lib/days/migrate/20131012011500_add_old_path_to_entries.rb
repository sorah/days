class AddOldPathToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :old_path, :string, default: nil
    add_index :entries, :old_path
  end
end
