class Admin::OrdersController < ApplicationController
  def index
    @orders = Order.where(status: Order::NEXT_STEP.keys)
                   .includes(:customer, :delivery_zone, :delivery_date, order_items: { product_variant: :product })
                   .order(created_at: :desc)
  end

  def update
    order = Order.find(params[:id])
    order.update!(params.expect(order: [ :status ]))
    redirect_to admin_orders_path, notice: "#{order.number}: #{order.status.humanize}"
  end
end
