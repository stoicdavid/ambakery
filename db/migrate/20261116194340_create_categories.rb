class CreateCategories < ActiveRecord::Migration[8.1]
  class MigrationCategory < ActiveRecord::Base; self.table_name = "categories"; end
  class MigrationProduct  < ActiveRecord::Base; self.table_name = "products";   end

  LEGACY = {
    "tradicional" => { name: "Pan tradicional",    slug: "pan-tradicional",    tagline: "De siempre",   position: 0 },
    "especial"    => { name: "Selección especial", slug: "seleccion-especial", tagline: "De la casa",   position: 1 },
    "temporada"   => { name: "Día de Muertos",     slug: "dia-de-muertos",     tagline: "De temporada", position: 2,
                       seasonal: true, starts_on: "2026-10-01", ends_on: "2026-11-02" }
  }.freeze

  def up
    create_table :categories do |t|
      t.string  :name, null: false
      t.string  :slug, null: false
      t.string  :tagline
      t.text    :description
      t.integer :position, null: false, default: 0
      t.boolean :active,   null: false, default: true
      t.boolean :seasonal, null: false, default: false
      t.date    :starts_on
      t.date    :ends_on
      t.timestamps
    end
    add_index :categories, :slug, unique: true
    add_reference :products, :category, foreign_key: true

    MigrationCategory.reset_column_information
    MigrationProduct.reset_column_information
    LEGACY.each do |key, attrs|
      category = MigrationCategory.create!(attrs)
      MigrationProduct.where(category: key).update_all(category_id: category.id)
    end
    MigrationCategory.create!(name: "Navidad", slug: "navidad", tagline: "De temporada", position: 3,
                              seasonal: true, starts_on: "2026-12-01", ends_on: "2027-01-06",
                              description: "Rosca de reyes y pan navideño")

    remove_index  :products, [ :category, :active ]
    remove_column :products, :category
  end

  def down = raise(ActiveRecord::IrreversibleMigration)
end