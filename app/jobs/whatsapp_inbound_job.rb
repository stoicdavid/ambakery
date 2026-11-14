class WhatsappInboundJob < ApplicationJob
  queue_as :default

  # Process one customer's messages one at a time, so two quick taps can't both edit the same cart
  limits_concurrency to: 1, key: ->(body) {
    JSON.parse(body).dig("entry", 0, "changes", 0, "value", "messages", 0, "from") || "statuses"
  }

  def perform(raw_body)
    JSON.parse(raw_body).fetch("entry", []).each do |entry|
      entry.fetch("changes", []).each do |change|
        value = change["value"] || {}
        Array(value["statuses"]).each { |status| record_status(status) }
        Array(value["messages"]).each { |message| handle_message(message, value) }
      end
    end
  end

  private

  def handle_message(message, value)
    contact  = Array(value["contacts"]).find { |c| c["wa_id"] == message["from"] } || {}
    customer = Customer.from_whatsapp!(wa_id: message["from"], name: contact.dig("profile", "name"))
    conversation = WhatsappConversation.for(customer)

    inbound = WhatsappMessage.record_inbound!(conversation: conversation, message: message)
    return unless inbound   # nil = Meta resent a message we already processed

    Whatsapp::Client.new.send_text(customer.whatsapp_to, "Recibí: #{inbound.body}", conversation: conversation)
  end

  def record_status(status)
    message = WhatsappMessage.find_by(wamid: status["id"]) or return
    message.update!(status: status["status"], error_message: status.dig("errors", 0, "message"))
  end
end