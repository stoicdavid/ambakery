class Product < ApplicationRecord
  belongs_to :category
  has_many :variants, -> { order(:position) },
           class_name: "ProductVariant", dependent: :destroy, inverse_of: :product
  has_many :order_items, through: :variants

  accepts_nested_attributes_for :variants, allow_destroy: true, reject_if: ->(attrs) { attrs[:name].blank? }
  before_destroy :ensure_no_orders, prepend: true

  # WhatsApp list rows allow 24 characters for the title and 72 for the description.
  validates :name, presence: true, length: { maximum: 24 }
  validates :description, length: { maximum: 72 }
  validate :needs_a_variant

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

  private

  def ensure_no_orders
    return unless order_items.exists?
    errors.add(:base, "ya tiene pedidos")
    throw :abort
  end

  def needs_a_variant
    return if variants.reject(&:marked_for_destruction?).any?
    errors.add(:base, "Agrega al menos una presentación con precio")
  end
end