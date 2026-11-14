class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :status,      null: false, default: "draft"
      t.string :channel,     null: false, default: "whatsapp"
      t.string :fulfillment, null: false, default: "pickup"
      t.date :scheduled_on
      t.string :time_slot
      t.string :string
      t.text :delivery_address
      t.decimal :latitude,  precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.text :notes
      t.integer :total_cents, null: false, default: 0

      t.timestamps
    end
    add_index :orders, [:scheduled_on, :status]   # powers the daily production report
  end
end
