class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :phone
      t.string :wa_id

      t.timestamps
    end
    add_index :customers, :phone, unique: true
    add_index :customers, :wa_id, unique: true
  end
end
