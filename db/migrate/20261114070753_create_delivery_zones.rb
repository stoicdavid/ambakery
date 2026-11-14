class CreateDeliveryZones < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_zones do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
