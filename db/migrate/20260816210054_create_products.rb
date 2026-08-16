class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.integer :order
      t.decimal :price, precision: 8, scale: 2

      t.timestamps
    end
  end
end
