class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :login_name
      t.string :password_digest

      t.string :name
    end

    add_index :users, :login_name
  end
end
