class Product < ApplicationRecord
  before_validation :generate_slug, on: :create
  has_one_attached :image
  after_commit -> { broadcast_refresh_later_to "products" }
  
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  private

  def generate_slug
    base = name.parameterize
    candidate = base
    counter = 2
    while Product.exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end
end
