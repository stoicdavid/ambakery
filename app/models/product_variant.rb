class ProductVariant < ApplicationRecord
  belongs_to :product, inverse_of: :variants
  has_many :order_items, dependent: :restrict_with_error

  validates :name, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  def display_name = "#{product.name} · #{name}"

  # The admin form uses pesos ("12.50"); the database keeps cents.
  def price = price_cents && price_cents / 100.0

  def price=(value)
    self.price_cents = value.blank? ? nil : (BigDecimal(value.to_s) * 100).round
  rescue ArgumentError
    self.price_cents = nil
  end
end