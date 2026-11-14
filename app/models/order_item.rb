class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product_variant

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  before_validation :snapshot_price, on: :create
  after_commit -> { order.recalculate_total! }

  def subtotal_cents = quantity * unit_price_cents

  private

  # Copy the price when the item is added, so changing a price later doesn't change past orders
  def snapshot_price
    self.unit_price_cents ||= product_variant&.price_cents
  end
end