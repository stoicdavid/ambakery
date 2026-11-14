class OrderNotificationJob < ApplicationJob
  TEMPLATES = {
    "confirmed" => [ "pedido_confirmado", ->(o) { [ o.number, o.delivery_date.label, o.delivery_zone.name,
                                                  ActiveSupport::NumberHelper.number_to_currency(o.total_cents / 100.0) ] } ],
    "ready"     => [ "pedido_listo",      ->(o) { [ o.number, o.delivery_zone.name ] } ],
    "reminder"  => [ "pedido_recordatorio", ->(o) { [ o.delivery_date.label, o.number, o.delivery_zone.name ] } ]
  }.freeze

  # kind defaults to the order's status; the reminder job passes "reminder"
  def perform(order, kind = nil)
    name, params = TEMPLATES[kind || order.status]
    return unless name

    customer = order.customer
    first_name = customer.name.to_s.split.first.presence || "cliente"
    Whatsapp::Client.new.send_template(customer.whatsapp_to, name, [ first_name, *params.call(order) ],
                                       conversation: WhatsappConversation.for(customer))
  end
end
