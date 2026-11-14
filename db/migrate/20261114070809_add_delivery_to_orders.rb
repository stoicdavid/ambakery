class AddDeliveryToOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :delivery_zone, foreign_key: true
    add_reference :orders, :delivery_date, foreign_key: true
  end
end
