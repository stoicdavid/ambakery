class CreateWhatsappMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :whatsapp_messages do |t|
      t.references :whatsapp_conversation, null: false, foreign_key: true
      t.string :wamid
      t.string :direction, null: false        # "in" / "out"
      t.string :message_type
      t.text :body
      t.json   :payload, null: false, default: {}
      t.string :status                        # sent / delivered / read / failed
      t.text :error_message

      t.timestamps
    end
    add_index :whatsapp_messages, :wamid, unique: true
    add_index :whatsapp_messages, [:whatsapp_conversation_id, :created_at]
  end
end
