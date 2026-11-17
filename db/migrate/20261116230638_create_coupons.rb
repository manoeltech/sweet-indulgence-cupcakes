class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.string :code, null: false, limit: 30
      t.string :description, null: false, default: "", limit: 120
      t.integer :percentage, null: false
      t.date :valid_until, null: false
      t.integer :usage_limit
      t.integer :uses_count, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :coupons, :code, unique: true
    add_check_constraint :coupons, "percentage BETWEEN 1 AND 90", name: "coupons_percentage_range"
  end
end
