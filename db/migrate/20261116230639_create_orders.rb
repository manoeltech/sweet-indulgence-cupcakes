class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :code, null: false, limit: 12
      t.references :customer, null: false, foreign_key: { to_table: :users }
      t.references :courier, foreign_key: { to_table: :users }
      t.references :coupon, foreign_key: true
      t.references :delivery_zone, foreign_key: true
      t.string :status, null: false, default: "paid", limit: 30
      t.string :fulfillment, null: false, limit: 10       # delivery | pickup
      t.string :delivery_address, limit: 255
      t.string :payment_method, null: false, limit: 10    # credit | debit | pix
      t.string :card_last4, limit: 4                      # nunca guardamos o número completo
      t.string :pix_code, limit: 255
      t.decimal :subtotal, precision: 10, scale: 2, null: false
      t.decimal :discount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :shipping_fee, precision: 10, scale: 2, null: false, default: 0
      t.decimal :total, precision: 10, scale: 2, null: false

      t.timestamps
    end
    add_index :orders, :code, unique: true
    add_index :orders, :status
    add_index :orders, :created_at
    add_check_constraint :orders, "total >= 0", name: "orders_total_not_negative"
  end
end
