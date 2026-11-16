class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true, index: false
      t.references :cupcake, null: false, foreign_key: true
      t.integer :rating, null: false
      t.integer :delivery_rating, null: false
      t.text :comment, null: false, default: ""

      t.timestamps
    end
    add_index :reviews, [ :order_id, :cupcake_id ], unique: true
    add_check_constraint :reviews, "rating BETWEEN 1 AND 5", name: "reviews_rating_range"
    add_check_constraint :reviews, "delivery_rating BETWEEN 1 AND 5", name: "reviews_delivery_rating_range"
  end
end
