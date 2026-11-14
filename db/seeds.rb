# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

def product(name, category:, position:, variants: { "Pieza" => 0 }, **attrs)
  p = Product.find_or_create_by!(name: name) do |pr|
    pr.category = category
    pr.position = position
    pr.assign_attributes(attrs)
  end
  variants.each_with_index do |(vname, cents), i|
    p.variants.find_or_create_by!(name: vname) { |v| v.price_cents = cents; v.position = i }
  end
end

# Pan tradicional: sold by the piece. TODO: real prices
%w[Concha Pan\ de\ leche Azucarado Polveado Polvorón Chalupa
   Cartera Gusano Elote Taco Rosca\ de\ sal].each_with_index do |name, i|
  product(name, category: "tradicional", position: i)
end

# Selección especial de la casa
product "Apastelada",              category: "especial", position: 0,
        description: "Rellena de queso fresco"
product "Gusano y empanada",       category: "especial", position: 1,
        description: "Rellenos de queso fresco",
        variants: { "Gusano" => 0, "Empanada" => 0 }
product "Galletas de mantequilla", category: "especial", position: 2,
        variants: { "Sencillas" => 0, "Con nuez" => 0 }
product "Besitos de nuez",         category: "especial", position: 3,
        variants: { "Paquete 250 g" => 0 }
product "Frutas de horno",         category: "especial", position: 4,
        variants: { "Paquete 12 pzas" => 0 }
product "Pemoles",                 category: "especial", position: 5,
        description: "Galletas de maíz con mantequilla",
        variants: { "Paquete 250 g" => 0 }

# Seasonal: hidden until Día de Muertos
product "Pan de muerto", category: "temporada", position: 0, active: false