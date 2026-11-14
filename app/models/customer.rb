class Customer < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error
  has_one  :whatsapp_conversation, dependent: :destroy

  def self.from_whatsapp!(wa_id:, name: nil)
    find_or_create_by!(wa_id: wa_id) do |c|
      c.name  = name
      c.phone = normalize_mx(wa_id)
    end
  end

  def self.normalize_mx(number)
    number.to_s.gsub(/\D/, "").sub(/\A521(\d{10})\z/, '52\1')
  end
  
  def whatsapp_to = phone.presence || wa_id
end
