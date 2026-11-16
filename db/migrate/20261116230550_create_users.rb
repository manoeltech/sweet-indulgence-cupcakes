class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false, limit: 120
      t.string :email, null: false, limit: 160
      t.string :phone, limit: 20
      t.string :password_digest, null: false
      t.string :role, null: false, default: "customer", limit: 20
      t.boolean :notifications_enabled, null: false, default: true

      t.timestamps
    end
    add_index :users, :email, unique: true
    add_check_constraint :users, "role IN ('customer', 'admin', 'courier')", name: "users_role_valid"
  end
end
