class WhatsappConversation < ApplicationRecord
  SERVICE_WINDOW = 24.hours
  STATES = %w[idle choose_category choose_product choose_variant quantity
              add_more fulfillment address date time_slot notes confirm].freeze

  belongs_to :customer
  belongs_to :draft_order, class_name: "Order", optional: true
  has_many   :messages, class_name: "WhatsappMessage", dependent: :destroy

  validates :state, inclusion: { in: STATES }

  def self.for(customer) = find_or_create_by!(customer: customer)

  # Free-form replies are only allowed within 24h of the customer's last message
  def window_open? = last_inbound_at.present? && last_inbound_at > SERVICE_WINDOW.ago

  def transition!(new_state, **ctx)
    update!(state: new_state, context: context.merge(ctx.stringify_keys))
  end

  def current_order!
    draft_order || begin
      order = customer.orders.create!(channel: "whatsapp")
      update!(draft_order: order)
      order
    end
  end

  def reset!
    draft_order&.cancelled! if draft_order&.draft?
    update!(state: "idle", context: {}, draft_order: nil)
  end
end