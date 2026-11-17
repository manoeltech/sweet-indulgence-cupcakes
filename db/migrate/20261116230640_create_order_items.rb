class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :cupcake, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 8, scale: 2, null: false # preço congelado no momento da compra

      t.timestamps
    end
    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
  end
end
