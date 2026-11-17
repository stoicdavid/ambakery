class Admin::DashboardController < Admin::BaseController
  def index
    @tomorrow = Date.tomorrow
    @pending  = Order.where(status: %w[pending_payment confirmed in_production ready]).count
    @units    = OrderItem.joins(:order).merge(Order.committed.where(scheduled_on: @tomorrow)).sum(:quantity)
    @products = Product.where(active: true).count
    @season   = Category.on_menu.find(&:seasonal?)
  end
end