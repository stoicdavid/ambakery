class AddUniqueIndexToProductsSlug < ActiveRecord::Migration[8.1]
  def change
    add_index :products, :slug, unique: true
  end
end
