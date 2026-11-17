class CreateCupcakes < ActiveRecord::Migration[8.1]
  def change
    create_table :cupcakes do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false, limit: 80
      t.text :description, null: false
      t.text :ingredients, null: false, default: ""
      t.decimal :price, precision: 8, scale: 2, null: false
      t.integer :stock, null: false, default: 0
      t.integer :min_stock, null: false, default: 5
      t.integer :calories
      t.decimal :fat_grams, precision: 5, scale: 1
      t.decimal :sugar_grams, precision: 5, scale: 1
      t.string :allergens, null: false, default: "", limit: 200
      t.string :color, null: false, default: "#f9a8d4", limit: 7 # cor da cobertura na ilustração
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_check_constraint :cupcakes, "price > 0", name: "cupcakes_price_positive"
    add_check_constraint :cupcakes, "stock >= 0", name: "cupcakes_stock_not_negative"
  end
end
