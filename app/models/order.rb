class Order < ApplicationRecord
  belongs_to :customer
  belongs_to :delivery_zone, optional: true
  belongs_to :delivery_date, optional: true

  before_validation { self.scheduled_on = delivery_date&.date }   # reports still query scheduled_on
  after_update_commit :notify_customer, if: -> { saved_change_to_status? && channel_whatsapp? }


  NEXT_STEP = { "pending_payment" => [ "confirmed", "Pago recibido" ],
                "confirmed"       => [ "in_production", "En producción" ],
                "in_production"   => [ "ready", "Listo" ],
                "ready"           => [ "delivered", "Entregado" ] }.freeze
  has_many :order_items, dependent: :destroy
  has_many :product_variants, through: :order_items


  # A draft becoming pending_payment means a new order: show it on the board
  after_update_commit -> { broadcast_prepend_later_to "admin_orders", target: "orders",
                                                       partial: "admin/orders/order" },
                      if: -> { saved_change_to_status?(from: "draft") }

  enum :status, %w[draft pending_payment confirmed in_production
                   ready delivered cancelled].index_by(&:itself),
       default: "draft", validate: true
  enum :channel, %w[whatsapp web counter].index_by(&:itself),
       prefix: true, validate: true
  enum :fulfillment, %w[pickup delivery].index_by(&:itself), validate: true

  TIME_SLOTS = %w[09-12 12-15 15-18].freeze

  # Orders that take up kitchen capacity and show up in the production report
  scope :committed, -> { where(status: %w[pending_payment confirmed in_production ready]) }

  # with_options unless: :draft? do
  #  validates :scheduled_on, :time_slot, presence: true
  #  validates :time_slot, inclusion: { in: TIME_SLOTS }
  #  validates :delivery_address, presence: true, if: :delivery?
  #  validate  :has_items
  # end

  with_options if: :placed? do
    validates :delivery_zone, :delivery_date, presence: true
    validate  :has_items
  end

  def placed? = !draft? && !cancelled?

  def number = format("AMB-%04d", id)

  def recalculate_total!
    update!(total_cents: order_items.sum("quantity * unit_price_cents"))
  end




  private

  def has_items
    errors.add(:base, "El pedido no tiene productos") if order_items.empty?
  end

  def notify_customer = OrderNotificationJob.perform_later(self)
end
