require "test_helper"

class WhatsappWebhooksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "answers Meta's verification challenge" do
    get "/webhooks/whatsapp", params: { "hub.mode" => "subscribe",
      "hub.verify_token" => Whatsapp.config[:verify_token], "hub.challenge" => "42" }
    assert_response :success
    assert_equal "42", response.body
  end

  test "rejects a bad signature" do
    post "/webhooks/whatsapp", params: "{}",
      headers: { "Content-Type" => "application/json", "X-Hub-Signature-256" => "sha256=nope" }
    assert_response :unauthorized
  end

  test "queues a correctly signed payload" do
    body = file_fixture("whatsapp_text_message.json").read
    sig  = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", Whatsapp.config[:app_secret], body)
    assert_enqueued_with(job: WhatsappInboundJob) do
      post "/webhooks/whatsapp", params: body,
        headers: { "Content-Type" => "application/json", "X-Hub-Signature-256" => sig }
    end
    assert_response :ok
  end
end