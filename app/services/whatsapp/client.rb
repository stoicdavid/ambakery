require "net/http"

module Whatsapp
  class Client
    class Error < StandardError; end

    def initialize(config = Whatsapp.config)
      @config = config
    end

    def send_text(to, body, conversation: nil)
      deliver to, conversation, type: "text", text: { body: body, preview_url: false }
    end

    # buttons: { "id" => "Title" }. Max 3, titles ≤ 20 chars
    def send_buttons(to, body, buttons, conversation: nil)
      deliver to, conversation, type: "interactive", interactive: {
        type: "button", body: { text: body.truncate(1024) },
        action: { buttons: buttons.first(3).map { |id, title|
          { type: "reply", reply: { id: id, title: title.truncate(20) } } } }
      }
    end

    # rows: [{ id:, title:, description: }]. Max 10, title ≤ 24, description ≤ 72
    def send_list(to, body, button_label, rows, conversation: nil)
      rows = rows.first(10).map do |r|
        { id: r[:id], title: r[:title].truncate(24), description: r[:description]&.truncate(72) }.compact
      end
      deliver to, conversation, type: "interactive", interactive: {
        type: "list", body: { text: body.truncate(1024) },
        action: { button: button_label.truncate(20), sections: [{ title: "Opciones", rows: rows }] }
      }
    end

    def send_template(to, name, params = [], language: "es_MX", conversation: nil)
      components = params.any? ?
        [{ type: "body", parameters: params.map { |p| { type: "text", text: p.to_s } } }] : []
      deliver to, conversation, type: "template",
              template: { name: name, language: { code: language }, components: components }
    end

    private

    def deliver(to, conversation, **message)
      payload = { messaging_product: "whatsapp", recipient_type: "individual", to: to }.merge(message)
      wamid = post("/#{@config[:phone_number_id]}/messages", payload).dig("messages", 0, "id")
      conversation&.messages&.create!(direction: :outbound, wamid: wamid,
                                       message_type: message[:type], payload: payload, status: "accepted")
      wamid
    end

    def post(path, payload)
      uri  = URI("https://graph.facebook.com/#{@config[:api_version]}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json",
                                         "Authorization" => "Bearer #{@config[:access_token]}")
      request.body = payload.to_json
      response = http.request(request)
      body = JSON.parse(response.body) rescue {}
      return body if response.is_a?(Net::HTTPSuccess)

      raise Error, "#{response.code} (#{body.dig('error', 'code')}) #{body.dig('error', 'message')}"
    end
  end
end