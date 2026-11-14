class Admin::ConversationsController < ApplicationController
  def index
    @conversations = WhatsappConversation.includes(:customer).order(last_inbound_at: :desc).limit(50)
  end

  def show
    @conversation = WhatsappConversation.find(params[:id])
    @messages = @conversation.messages.order(:created_at).last(100)
  end
end
