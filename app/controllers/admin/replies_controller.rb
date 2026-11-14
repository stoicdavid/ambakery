class Admin::RepliesController < ApplicationController
  def create
    conv = WhatsappConversation.find(params[:conversation_id])
    if conv.window_open?
      Whatsapp::Client.new.send_text(conv.customer.whatsapp_to, params.expect(:body), conversation: conv)
      conv.update!(state: "idle")   # next customer message restarts the bot
      redirect_to admin_conversation_path(conv)
    else
      redirect_to admin_conversation_path(conv), alert: "Pasaron más de 24 h: ya solo se pueden enviar plantillas."
    end
  end
end