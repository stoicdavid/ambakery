class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string  :name, null: false
      t.string  :category, null: false          # "pan_dulce", "pasteles", "galletas"…
      t.text :description
      t.integer :price_cents, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.integer :daily_capacity                 # nil = unlimited
      t.integer :lead_time_days, null: false, default: 0   # cakes: 2
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :products, [:category, :active]
  end
end
