class CreateProductVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :price_cents, null: false
      t.boolean :active, default: true
      t.integer :position
      t.timestamps
    end
  end
end
