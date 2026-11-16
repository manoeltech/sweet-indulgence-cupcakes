class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :order, foreign_key: true
      t.string :message, null: false, limit: 255
      t.boolean :read, null: false, default: false

      t.timestamps
    end
  end
end
