require "test_helper"

class Whatsapp::ClientTest < ActiveSupport::TestCase
  test "sends buttons and logs the outbound message" do
    stub = stub_request(:post, %r{graph\.facebook\.com/v27\.0/PHONE_ID/messages})
             .with { |req| JSON.parse(req.body).dig("interactive", "type") == "button" }
             .to_return(body: { messages: [{ id: "wamid.OUT1" }] }.to_json)
    conv = WhatsappConversation.for(Customer.from_whatsapp!(wa_id: "5215500000000"))

    wamid = Whatsapp::Client.new.send_buttons("5215500000000", "Hola", { "a" => "Uno" }, conversation: conv)

    assert_requested stub
    assert_equal "wamid.OUT1", wamid
    assert conv.messages.outbound.exists?(wamid: "wamid.OUT1")
  end

  test "raises on Meta errors" do
    stub_request(:post, /graph\.facebook\.com/)
      .to_return(status: 400, body: { error: { code: 131047, message: "Re-engagement message" } }.to_json)
    assert_raises(Whatsapp::Client::Error) { Whatsapp::Client.new.send_text("52155", "hola") }
  end
end