Sequel.migration do
  change do
    alter_table(:entries) do
      add_column :old_path, String, default: nil
      add_index :old_path, name: :index_entries_on_old_path
    end
  end
end
