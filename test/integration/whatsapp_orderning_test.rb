require "test_helper"

class WhatsappOrderingTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    # A new wamid per request, like real Meta. A fixed ID would break the unique index on wamid
    stub_request(:post, %r{graph\.facebook\.com/.+/messages})
      .to_return { { body: { messages: [ { id: "wamid.out.#{SecureRandom.hex(6)}" } ] }.to_json } }
    @category = Category.create!(name: "Pan de prueba", slug: "pan-de-prueba")
    product  = Product.create!(name: "Concha", category: @category,
                                 variants_attributes: [ { name: "Vainilla", price_cents: 2_200 } ])
    @variant = product.variants.first
    @zone = DeliveryZone.create!(name: "Valle de San Javier")
    @date = @zone.delivery_dates.create!(date: Date.tomorrow, cutoff_at: 1.hour.from_now)
  end

  def whatsapp(input)
    message = if input.include?(":")
      { type: "interactive", interactive: { type: "button_reply", button_reply: { id: input, title: input } } }
    else
      { type: "text", text: { body: input } }
    end
    body = { object: "whatsapp_business_account", entry: [ { id: "WABA_ID", changes: [ { field: "messages",
      value: { messaging_product: "whatsapp", metadata: { phone_number_id: "PHONE_ID" },
               contacts: [ { wa_id: "5215500000000", profile: { name: "Ana" } } ],
               messages: [ { from: "5215500000000", id: "wamid.#{SecureRandom.hex(6)}",
                            timestamp: Time.now.to_i.to_s, **message } ] } } ] } ] }.to_json
    sig = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", Whatsapp.config[:app_secret], body)

    perform_enqueued_jobs only: WhatsappInboundJob do
      post "/webhooks/whatsapp", params: body,
        headers: { "Content-Type" => "application/json", "X-Hub-Signature-256" => sig }
    end
  end

  test "an order placed on WhatsApp appears on tomorrow's production report" do
    [ "hola", "menu:order", "cat:#{@category.id}", "prod:#{@variant.product_id}", "12",
     "more:no", "zone:#{@zone.id}", "date:#{@date.id}", "notes:skip", "confirm:yes" ].each { whatsapp(_1) }

    assert Order.last.pending_payment?

    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    get admin_production_path(date: Date.tomorrow)
    assert_response :success
    assert_match "Concha · Vainilla", response.body
    assert_match "12", response.body
  end
end
