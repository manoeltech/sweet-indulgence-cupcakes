class CreateContactLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :contact_logs do |t|
      t.references :order, null: false, foreign_key: true
      t.references :courier, null: false, foreign_key: { to_table: :users }
      t.string :channel, null: false, limit: 10 # call | whatsapp

      t.timestamps
    end
  end
end
