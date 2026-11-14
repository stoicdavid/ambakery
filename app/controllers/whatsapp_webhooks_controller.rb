# Inherits from ActionController::API: no login, no CSRF. The signature check protects it instead.
class WhatsappWebhooksController < ActionController::API
  # Meta calls this once when you save the callback URL
  def verify
    if params["hub.mode"] == "subscribe" &&
       ActiveSupport::SecurityUtils.secure_compare(params["hub.verify_token"].to_s, wa_config[:verify_token].to_s)
      render plain: params["hub.challenge"]
    else
      head :forbidden
    end
  end

  def receive
    body = request.raw_post
    return head :unauthorized unless valid_signature?(body)

    WhatsappInboundJob.perform_later(body)
    head :ok
  end

  private

  def valid_signature?(body)
    expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", wa_config[:app_secret].to_s, body)
    ActiveSupport::SecurityUtils.secure_compare(expected, request.headers["X-Hub-Signature-256"].to_s)
  end

  # Not "config": Rails controllers already have a config method (used for logger, etc.)
  def wa_config = Whatsapp.config
end