class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: %i[edit update destroy]

  def index
    @categories = Category.ordered.includes(products: :variants)
  end

  def new
    @category = Category.new(position: Category.maximum(:position).to_i + 1)
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to admin_categories_path, notice: "Categoría «#{@category.name}» creada"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: "Categoría actualizada"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @category.destroy
      redirect_to admin_categories_path, notice: "Categoría eliminada"
    else
      redirect_to edit_admin_category_path(@category), alert: "Tiene productos: muévelos a otra categoría o desactívala."
    end
  end

  private

  def set_category = @category = Category.find(params[:id])

  def category_params
    params.expect(category: %i[name tagline description position active seasonal starts_on ends_on])
  end
end