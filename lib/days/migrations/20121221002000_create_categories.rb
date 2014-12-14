Sequel.migration do
  change do
    create_table(:categories, ignore_index_errors: true) do
      primary_key :id
      String :name, size: 255, null: false

      index [:name], name: :index_categories_on_name
    end

    create_table(:categories_entries, ignore_index_errors: true) do
      primary_key :id
      Integer :category_id
      Integer :entry_id

      index [:category_id], name: :index_categories_entries_on_category_id
      index [:entry_id], name: :index_categories_entries_on_entry_id
    end
  end
end
