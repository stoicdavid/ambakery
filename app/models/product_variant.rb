class ProductVariant < ApplicationRecord
  belongs_to :product
  validates :name, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  def display_name = "#{product.name} · #{name}"
end