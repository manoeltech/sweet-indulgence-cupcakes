class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :street, null: false, limit: 160
      t.string :number, null: false, limit: 10
      t.string :district, null: false, limit: 80
      t.string :zip_code, null: false, limit: 9

      t.timestamps
    end
  end
end
