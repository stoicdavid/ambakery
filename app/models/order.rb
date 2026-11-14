class Order < ApplicationRecord
  belongs_to :customer
  has_many :order_items, dependent: :destroy
  has_many :product_variants, through: :order_items

  enum :status, %w[draft pending_payment confirmed in_production
                   ready delivered cancelled].index_by(&:itself),
       default: "draft", validate: true
  enum :channel, %w[whatsapp web counter].index_by(&:itself),
       prefix: true, validate: true
  enum :fulfillment, %w[pickup delivery].index_by(&:itself), validate: true

  TIME_SLOTS = %w[09-12 12-15 15-18].freeze

  # Orders that take up kitchen capacity and show up in the production report
  scope :committed, -> { where(status: %w[pending_payment confirmed in_production ready]) }

  with_options unless: :draft? do
    validates :scheduled_on, :time_slot, presence: true
    validates :time_slot, inclusion: { in: TIME_SLOTS }
    validates :delivery_address, presence: true, if: :delivery?
    validate  :has_items
  end

  def number = format("AMB-%04d", id)

  def recalculate_total!
    update!(total_cents: order_items.sum("quantity * unit_price_cents"))
  end

  private

  def has_items
    errors.add(:base, "El pedido no tiene productos") if order_items.empty?
  end
end