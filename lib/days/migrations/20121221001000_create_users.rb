Sequel.migration do
  change do
    create_table(:users, ignore_index_errors: true) do
      primary_key :id
      String :login_name, size: 255, null: false
      File :password_digest
      String :name, size: 255

      index [:login_name], name: :index_users_on_login_name
    end

    add_index :users, :login_name
  end
end
