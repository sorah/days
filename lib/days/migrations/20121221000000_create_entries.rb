Sequel.migration do
  change do
    create_table(:entries, ignore_index_errors: true) do
      primary_key :id
      String :title, size: 255, null: false
      String :body, text: true, null: false
      String :rendered, text: true, null: false
      String :slug, size: 255, null: false
      Integer :user_id
      DateTime :published_at
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:published_at], name: :index_entries_on_published_at
      index [:slug], name: :index_entries_on_slug
      index [:user_id], name: :index_entries_on_user_id
    end
  end
end
