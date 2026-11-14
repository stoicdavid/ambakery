class Customer < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error
  has_one  :whatsapp_conversation, dependent: :destroy

  def self.from_whatsapp!(wa_id:, name: nil)
    find_or_create_by!(wa_id: wa_id) { |c| c.name = name; c.phone = wa_id }
  end
end
