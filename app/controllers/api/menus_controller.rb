class Api::MenusController < ActionController::API
  def show
    expires_in 5.minutes, public: true
    render json: { generated_at: Time.current, categories: categories }
  end

  private

  def categories
    Category.on_menu.filter_map do |category|
      products = category.products.available.includes(:variants).filter_map do |product|
        variants = product.variants.select(&:active)
        next if variants.empty?
        { id: product.id, name: product.name, description: product.description,
          variants: variants.map { |v| { name: v.name, price: v.price } } }
      end
      next if products.empty?
      { slug: category.slug, name: category.name, tagline: category.tagline,
        description: category.description, seasonal: category.seasonal?, products: products }
    end
  end
end