class CreateDeliveryDates < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_dates do |t|
      t.references :delivery_zone, null: false, foreign_key: true
      t.date :date
      t.datetime :cutoff_at
      t.integer :capacity

      t.timestamps
    end
  end
end
