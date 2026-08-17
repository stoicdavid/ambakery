class Product < ApplicationRecord
  before_validation :generate_slug, on: :create
  has_one_attached :image
  after_commit -> { broadcast_refresh_later_to "products" }

  validates :description, :image, presence: true
  validates :name,:slug, presence: true, uniqueness: true
  validates :price, numericality: { greater_than_or_equal_to: 0.01 }
  validate :acceptable_image

  private

  def generate_slug
    return if name.blank? || slug.present?
    base = name.parameterize
    candidate = base
    counter = 2
    while Product.exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end

  def acceptable_image
    return unless image.attached?
    unless image.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:image, "must be a JPEG or PNG or GIF")
    end
  end
end
