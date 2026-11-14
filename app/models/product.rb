class Product < ApplicationRecord
  CATEGORIES = %w[tradicional especial temporada].freeze

  has_many :variants, -> { order(:position) },
           class_name: "ProductVariant", dependent: :destroy

  validates :name, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  scope :available, -> { where(active: true).order(:position) }

  def units_booked_on(date)
    OrderItem.joins(:order, :product_variant)
             .where(product_variants: { product_id: id })
             .merge(Order.committed.where(scheduled_on: date))
             .sum(:quantity)
  end

  def available_on?(date, quantity = 1)
    return false if date < Date.current + lead_time_days
    daily_capacity.nil? || units_booked_on(date) + quantity <= daily_capacity
  end
end