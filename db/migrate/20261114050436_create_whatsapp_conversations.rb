class CreateWhatsappConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :whatsapp_conversations do |t|
      t.references :customer, null: false, foreign_key: true, index: { unique: true }
      t.string     :state,   null: false, default: "idle"
      t.json       :context, null: false, default: {}
      t.datetime :last_inbound_at
      t.references :draft_order, foreign_key: { to_table: :orders }   # nullable

      t.timestamps
    end
  end
end
