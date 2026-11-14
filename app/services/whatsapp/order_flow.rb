module Whatsapp
  class OrderFlow
    MENU_WORDS   = %w[menu menú inicio hola].freeze
    CANCEL_WORDS = %w[cancelar salir].freeze
    HUMAN_WORDS  = %w[humano persona asesor].freeze

    def initialize(conversation, message, client: Client.new)
      @conv     = conversation
      @customer = conversation.customer
      @input    = message.body.to_s.strip
      @client   = client
    end

    def call
      word = @input.downcase
      return ask_menu if MENU_WORDS.include?(word) || @conv.state == "idle"
      return cancel   if CANCEL_WORDS.include?(word)
      return hand_off if HUMAN_WORDS.include?(word)

      send("on_#{@conv.state}")
    end

    private

    # ── Menu ──────────────────────────────────────────────
    def ask_menu
      hi = @customer.name.present? ? "¡Hola #{@customer.name.split.first}!" : "¡Hola!"
      buttons "#{hi} 🥐 Soy el asistente de Amora Masa. ¿Qué quieres hacer?",
              "menu:order" => "Hacer pedido", "menu:info" => "Entregas", "menu:human" => "Hablar con alguien"
      @conv.transition!("menu")
    end

    def on_menu
      case picked("menu")
      when "order" then ask_choose_category
      when "info"  then text(delivery_info); ask_menu
      when "human" then hand_off
      else retry_state
      end
    end

    # ── Catalog ───────────────────────────────────────────
    def ask_choose_category
      rows = Product::CATEGORY_NAMES.filter_map do |key, name|
        { id: "cat:#{key}", title: name } if Product.available.exists?(category: key)
      end
      list "Elige una categoría:", "Ver categorías", rows
      @conv.transition!("choose_category")
    end

    def on_choose_category
      category = picked("cat")
      return retry_state unless Product::CATEGORIES.include?(category)
      remember category: category
      ask_choose_product
    end

    def ask_choose_product
      products = Product.available.where(category: ctx["category"])
      list "¿Qué se te antoja?", "Ver productos",
           products.map { |p| { id: "prod:#{p.id}", title: p.name, description: p.description } }
      @conv.transition!("choose_product")
    end

    def on_choose_product
      product = Product.available.find_by(id: picked("prod"))
      return retry_state unless product

      variants = product.variants.where(active: true)
      if variants.one?
        remember variant_id: variants.first.id
        ask_quantity
      else
        remember product_id: product.id
        ask_choose_variant
      end
    end

    def ask_choose_variant
      product = Product.find(ctx["product_id"])
      list "#{product.name}: elige una opción", "Ver opciones",
           product.variants.where(active: true).map { |v|
             { id: "var:#{v.id}", title: v.name, description: money(v.price_cents) } }
      @conv.transition!("choose_variant")
    end

    def on_choose_variant
      variant = ProductVariant.where(active: true, product_id: ctx["product_id"]).find_by(id: picked("var"))
      return retry_state unless variant
      remember variant_id: variant.id
      ask_quantity
    end

    def ask_quantity
      variant = ProductVariant.find(ctx["variant_id"])
      buttons "#{variant.display_name} (#{money(variant.price_cents)}). ¿Cuántas quieres? " \
              "Toca una opción o escribe el número.",
              "qty:1" => "1", "qty:6" => "6", "qty:12" => "12"
      @conv.transition!("quantity")
    end

    def on_quantity
      qty = (picked("qty") || @input)[/\A\d{1,3}\z/]&.to_i
      return retry_state unless qty&.positive?
      order.order_items.create!(product_variant_id: ctx["variant_id"], quantity: qty)
      ask_add_more
    end

    def ask_add_more
      buttons "🧺 Tu charola:\n#{cart_summary}\n\n¿Quieres agregar algo más?",
              "more:yes" => "Agregar más", "more:no" => "Continuar"
      @conv.transition!("add_more")
    end

    def on_add_more
      case picked("more")
      when "yes" then ask_choose_category
      when "no"  then ask_zone
      else retry_state
      end
    end

    # ── Delivery ──────────────────────────────────────────
    def ask_zone
      zones = DeliveryZone.available
      if zones.none?
        text "Por ahora no tenemos zonas de entrega configuradas 😔 Te comunico con el equipo."
        return hand_off
      end
      list "¿Dónde quieres recibir tu pedido?", "Ver zonas",
           zones.map { |z| { id: "zone:#{z.id}", title: z.name, description: z.description } }
      @conv.transition!("zone")
    end

    def on_zone
      zone = DeliveryZone.available.find_by(id: picked("zone"))
      return retry_state unless zone
      remember zone_id: zone.id
      ask_date
    end

    def ask_date
      dates = DeliveryDate.open.where(delivery_zone_id: ctx["zone_id"]).reject(&:full?).first(10)
      if dates.empty?
        text "Por ahora no hay fechas abiertas en esa zona 😔 Elige otra o escribe *humano* y te ayudamos."
        return ask_zone
      end
      list "Elige la fecha de entrega:", "Ver fechas", dates.map { |d| { id: "date:#{d.id}", title: d.label } }
      @conv.transition!("date")
    end

    def on_date
      date = DeliveryDate.open.find_by(id: picked("date"), delivery_zone_id: ctx["zone_id"])
      return retry_state if date.nil? || date.full?

      sold_out = order.order_items.includes(product_variant: :product).reject do |item|
        item.product_variant.product.available_on?(date.date, item.quantity)
      end
      if sold_out.any?
        names = sold_out.map { |i| i.product_variant.display_name }.join(", ")
        text "Para el #{date.label} ya no alcanzamos a preparar: #{names}. Elige otra fecha o escribe *menu*."
        return ask_date
      end

      order.update!(delivery_zone_id: ctx["zone_id"], delivery_date: date)
      ask_notes
    end

    def ask_notes
      buttons "¿Alguna indicación? (dirección exacta, hora aproximada, alergias…) Escríbela o toca *Sin notas*.",
              "notes:skip" => "Sin notas"
      @conv.transition!("notes")
    end

    def on_notes
      order.update!(notes: @input.truncate(500)) unless picked("notes") == "skip"
      ask_confirm
    end

    # ── Confirm ───────────────────────────────────────────
    def ask_confirm
      o = order.reload
      summary = ["📋 *Resumen de tu pedido*", cart_summary, "",
                 "📍 #{o.delivery_zone.name}", "📅 #{o.delivery_date.label}",
                 (o.notes.present? ? "📝 #{o.notes}" : nil), "", "*Total: #{money(o.total_cents)}*"]
      buttons summary.compact.join("\n"),
              "confirm:yes" => "Confirmar", "confirm:edit" => "Cambiar", "confirm:no" => "Cancelar"
      @conv.transition!("confirm")
    end

    def on_confirm
      case picked("confirm")
      when "yes"
        o = order
        if o.update(status: "pending_payment")
          text "✅ ¡Listo! Tu pedido *#{o.number}* quedó registrado. " \
               "Te escribimos para confirmar el pago y la entrega. ¡Gracias! 🥐"
          @conv.update!(state: "idle", context: {}, draft_order: nil)
        else
          text "No pude registrar tu pedido: #{o.errors.full_messages.to_sentence}."
          ask_confirm
        end
      when "edit"
        order.order_items.destroy_all
        text "Empecemos de nuevo tu charola 🧺"
        ask_choose_category
      when "no" then cancel
      else retry_state
      end
    end

    # ── Escape hatches ────────────────────────────────────
    def cancel
      @conv.reset!
      text "Pedido cancelado. Escribe *menu* cuando quieras volver a empezar 👋"
    end

    def hand_off
      @conv.update!(state: "human")
      text "Listo, alguien del equipo te responde por aquí en cuanto pueda 🙌"
    end

    def on_human = nil   # bot stays quiet until the customer writes "menu"

    # ── Helpers ───────────────────────────────────────────
    def retry_state
      text "No entendí tu respuesta 🙈 Elige una opción de la lista."
      send("ask_#{@conv.state}")
    end

    def picked(prefix) = @input[/\A#{prefix}:(.+)\z/, 1]
    def ctx            = @conv.context
    def remember(**kv) = @conv.update!(context: ctx.merge(kv.stringify_keys))
    def order          = @conv.current_order!
    def to             = @customer.whatsapp_to

    def text(body)               = @client.send_text(to, body, conversation: @conv)
    def buttons(body, options)   = @client.send_buttons(to, body, options, conversation: @conv)
    def list(body, label, rows)  = @client.send_list(to, body, label, rows, conversation: @conv)

    def money(cents) = ActiveSupport::NumberHelper.number_to_currency(cents / 100.0, unit: "$")

    def cart_summary
      order.order_items.includes(product_variant: :product).map { |i|
        "• #{i.quantity} × #{i.product_variant.display_name}: #{money(i.subtotal_cents)}"
      }.join("\n")
    end

    def delivery_info
      DeliveryZone.available.map { |z| "📍 *#{z.name}*: #{z.description}" }.join("\n")
    end
  end
end