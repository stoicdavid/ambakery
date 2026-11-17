class Admin::ProductsController < Admin::BaseController
  before_action :set_product, only: %i[edit update destroy]

  def new
    @product = Product.new(category_id: params[:category_id])
    @product.variants.build(name: "Pieza")
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to admin_categories_path, notice: "«#{@product.name}» agregado"
    else
      blank_variant
      render :new, status: :unprocessable_content
    end
  end

  def edit = blank_variant

  def update
    if @product.update(product_params)
      redirect_to admin_categories_path, notice: "«#{@product.name}» actualizado"
    else
      blank_variant
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @product.destroy
      redirect_to admin_categories_path, notice: "«#{@product.name}» eliminado"
    else
      @product.update_column(:active, false)
      redirect_to admin_categories_path, alert: "«#{@product.name}» ya tiene pedidos, así que lo desactivé en lugar de borrarlo."
    end
  end

  private

  def set_product = @product = Product.find(params[:id])

  # One empty row so the team can add a new presentation (e.g. "Paquete 6 pzas").
  def blank_variant
    @product.variants.build unless @product.variants.any?(&:new_record?)
  end

  def product_params
    params.expect(product: [ :name, :category_id, :description, :active, :position, :daily_capacity, :lead_time_days,
                             variants_attributes: [ [ :id, :name, :price, :active, :position, :_destroy ] ] ])
  end
end