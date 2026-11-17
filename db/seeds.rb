# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

def category(name, slug:, position:, **attrs)
  Category.find_or_create_by!(slug: slug) do |c|
    c.name = name
    c.position = position
    c.assign_attributes(attrs)
  end
end

# Creates the product with its presentations in one save. Existing products are left alone,
# so running the seeds again doesn't overwrite prices the team changed in the admin.
def product(name, category:, position:, variants: { "Pieza" => 0 }, **attrs)
  Product.find_or_initialize_by(name: name).tap do |p|
    next if p.persisted?
    p.assign_attributes(category: category, position: position, **attrs)
    variants.each_with_index do |(vname, cents), i|
      p.variants.build(name: vname, price_cents: cents, position: i)
    end
    p.save!
  end
end

tradicional = category "Pan tradicional",    slug: "pan-tradicional",    position: 0, tagline: "De siempre"
especial    = category "Selección especial", slug: "seleccion-especial", position: 1, tagline: "De la casa"
muertos     = category "Día de Muertos",     slug: "dia-de-muertos",     position: 2, tagline: "De temporada",
                       seasonal: true, starts_on: Date.new(2026, 10, 1), ends_on: Date.new(2026, 11, 2),
                       description: "Pan de muerto hecho en casa, sólo por temporada"
navidad     = category "Navidad",            slug: "navidad",            position: 3, tagline: "De temporada",
                       seasonal: true, starts_on: Date.new(2026, 12, 1), ends_on: Date.new(2027, 1, 6),
                       description: "Rosca de reyes y pan navideño"

# Pan tradicional: sold by the piece. TODO: real prices
%w[Concha Pan\ de\ leche Azucarado Polveado Polvorón Chalupa
   Cartera Gusano Elote Taco Rosca\ de\ sal].each_with_index do |name, i|
  product(name, category: tradicional, position: i)
end

# Selección especial de la casa
product "Apastelada",              category: especial, position: 0,
        description: "Rellena de queso fresco"
product "Gusano y empanada",       category: especial, position: 1,
        description: "Rellenos de queso fresco",
        variants: { "Gusano" => 0, "Empanada" => 0 }
product "Galletas de mantequilla", category: especial, position: 2,
        variants: { "Sencillas" => 0, "Con nuez" => 0 }
product "Besitos de nuez",         category: especial, position: 3,
        variants: { "Paquete 250 g" => 0 }
product "Frutas de horno",         category: especial, position: 4,
        variants: { "Paquete 12 pzas" => 0 }
product "Pemoles",                 category: especial, position: 5,
        description: "Galletas de maíz con mantequilla",
        variants: { "Paquete 250 g" => 0 }

# Seasonal: each one shows up only inside its category's dates
product "Pan de muerto",   category: muertos, position: 0
product "Rosca de reyes",  category: navidad, position: 0,
        variants: { "Chica" => 0, "Mediana" => 0, "Grande" => 0 }