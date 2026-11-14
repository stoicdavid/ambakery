class WhatsappMessage < ApplicationRecord
  belongs_to :whatsapp_conversation
  enum :direction, { inbound: "in", outbound: "out" }, validate: true

  # Returns nil if this wamid was already processed (Meta retry)
  def self.record_inbound!(conversation:, message:)
    create!(
      whatsapp_conversation: conversation,
      direction: "in",
      wamid: message["id"],
      message_type: message["type"],
      body: extract_body(message),
      payload: message
    ).tap { conversation.update!(last_inbound_at: Time.current) }
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  # Turns text messages, button taps and list picks into one string the order flow can read
  def self.extract_body(m)
    case m["type"]
    when "text"        then m.dig("text", "body")
    when "interactive" then m.dig("interactive", "button_reply", "id") ||
                            m.dig("interactive", "list_reply", "id")
    when "location"    then m["location"].slice("latitude", "longitude").to_json
    end
  end
end