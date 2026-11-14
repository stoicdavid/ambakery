require "test_helper"

class WhatsappInboundJobTest < ActiveJob::TestCase
  setup do
    # Stubbed so the echo (5.3) and the order flow (6) can reply without calling Meta
    @send = stub_request(:post, %r{graph\.facebook\.com/.+/messages})
              .to_return(body: { messages: [{ id: "wamid.OUT" }] }.to_json)
  end

  test "creates the customer, logs the message once, replies once" do
    body = file_fixture("whatsapp_text_message.json").read
    2.times { WhatsappInboundJob.perform_now(body) }   # second run = Meta retry

    customer = Customer.find_by!(wa_id: "5215544922585")
    assert_equal "525544922585", customer.whatsapp_to
    assert_equal 1, WhatsappMessage.where(wamid: "wamid.TEST_IN_1").count
    assert_requested @send, times: 1   # the retry must not send a second reply
  end
end