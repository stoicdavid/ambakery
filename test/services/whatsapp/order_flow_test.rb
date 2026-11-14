require "test_helper"

class Whatsapp::OrderFlowTest < ActiveSupport::TestCase
  FakeClient = Struct.new(:sent) do
    def send_text(_to, body, **)              = sent << body
    def send_buttons(_to, _body, options, **) = sent << options.keys
    def send_list(_to, _body, _label, rows, **) = sent << rows.map { _1[:id] }
  end
  Msg = Struct.new(:body)

  setup do
    @client  = FakeClient.new([])
    @conv    = WhatsappConversation.for(Customer.from_whatsapp!(wa_id: "5215500000000", name: "Ana López"))
    @variant = Product.create!(name: "Concha", category: "tradicional")
                      .variants.create!(name: "Vainilla", price_cents: 2_200)
    @zone    = DeliveryZone.create!(name: "Valle de San Javier")
    @date    = @zone.delivery_dates.create!(date: 3.days.from_now.to_date, cutoff_at: 2.days.from_now)
  end

  def say(input)
    Whatsapp::OrderFlow.new(@conv.reload, Msg.new(input), client: @client).call
    @conv.reload
  end

  test "happy path creates a pending order" do
    assert_equal "menu",            say("hola").state
    assert_equal "choose_category", say("menu:order").state
    assert_equal "choose_product",  say("cat:tradicional").state
    assert_equal "quantity",        say("prod:#{@variant.product_id}").state   # single variant
    assert_equal "add_more",        say("6").state
    assert_equal "zone",            say("more:no").state
    assert_equal "date",            say("zone:#{@zone.id}").state
    assert_equal "notes",           say("date:#{@date.id}").state
    assert_equal "confirm",         say("notes:skip").state
    assert_equal "idle",            say("confirm:yes").state

    order = Order.last
    assert order.pending_payment?
    assert_equal 13_200, order.total_cents
    assert_equal @date.date, order.scheduled_on
  end

  test "nonsense repeats the question" do
    say "hola"
    assert_equal "menu", say("quiero pan").state
    assert_match "No entendí", @client.sent[-2]
  end

  test "refuses a full delivery date" do
    @date.update!(capacity: 0)
    say "hola"; say "menu:order"; say "cat:tradicional"; say "prod:#{@variant.product_id}"
    say "1"; say "more:no"
    assert_equal "zone", say("zone:#{@zone.id}").state   # no open dates → back to zones
  end

  test "cancelar works from any state" do
    say "hola"; say "menu:order"
    assert_equal "idle", say("cancelar").state
  end

  test "cancelar after adding items cancels the draft" do
    say "hola"; say "menu:order"; say "cat:tradicional"; say "prod:#{@variant.product_id}"; say "6"
    assert_equal "idle", say("cancelar").state
    assert Order.last.cancelled?
  end
end