require "test_helper"

class WhatsappMessageTest < ActiveSupport::TestCase
  setup do
    customer = Customer.from_whatsapp!(wa_id: "5215512345678", name: "Ana")
    @conv = WhatsappConversation.for(customer)
    @msg  = { "id" => "wamid.TEST1", "type" => "text", "text" => { "body" => "hola" } }
  end

  test "records once per wamid" do
    assert WhatsappMessage.record_inbound!(conversation: @conv, message: @msg)
    assert_nil WhatsappMessage.record_inbound!(conversation: @conv, message: @msg)
    assert_equal 1, @conv.messages.count
  end

  test "opens the 24h window" do
    WhatsappMessage.record_inbound!(conversation: @conv, message: @msg)
    assert @conv.reload.window_open?
    travel 25.hours
    refute @conv.window_open?
  end

  test "extracts button reply ids" do
    tap = { "type" => "interactive",
            "interactive" => { "button_reply" => { "id" => "slot:09-12" } } }
    assert_equal "slot:09-12", WhatsappMessage.extract_body(tap)
  end
end