class CreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string :login_name, null: false, unique: true
      t.binary :password_digest

      t.string :name
    end

    add_index :users, :login_name
  end
end
