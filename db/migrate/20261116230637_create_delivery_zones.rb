class CreateDeliveryZones < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_zones do |t|
      t.string :name, null: false, limit: 80
      t.decimal :fee, precision: 6, scale: 2, null: false
      t.integer :eta_minutes, null: false, default: 45

      t.timestamps
    end
    add_index :delivery_zones, :name, unique: true
    add_check_constraint :delivery_zones, "fee >= 0", name: "delivery_zones_fee_not_negative"
  end
end
