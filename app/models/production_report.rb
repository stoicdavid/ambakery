require "csv"

class ProductionReport
  attr_reader :date

  def initialize(date) = @date = date

  def orders = Order.committed.where(scheduled_on: date)

  # { ["Concha", "Vainilla"] => 48, ... }
  def totals
    OrderItem.joins(:order, product_variant: :product).merge(orders)
             .group("products.name", "product_variants.name")
             .order("products.name").sum(:quantity)
  end

  # Orders without a zone (old test data, manual entries) get their own group instead of crashing the report
  NO_ZONE = Struct.new(:name).new("Sin zona asignada")

  def orders_by_zone
    orders.includes(:customer, :delivery_zone, order_items: { product_variant: :product })
          .order(:created_at)
          .group_by { |o| o.delivery_zone || NO_ZONE }
          .sort_by { |zone, _| zone == NO_ZONE ? [ 1, "" ] : [ 0, zone.name ] }
          .to_h
  end

  def to_csv
    CSV.generate do |csv|
      csv << %w[Producto Variante Cantidad]
      totals.each { |(product, variant), qty| csv << [ product, variant, qty ] }
    end
  end
end
