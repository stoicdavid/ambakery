class Category < ApplicationRecord
  has_many :products, -> { order(:position) }, dependent: :restrict_with_error

  scope :ordered, -> { order(:position, :name) }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :starts_on, :ends_on, presence: true, if: :seasonal?
  before_validation { self.slug = name.to_s.parameterize if slug.blank? }

  # Active categories whose season includes the date (non-seasonal ones always do).
  def self.on_menu(date = Date.current)
    ordered.where(active: true).select { |category| category.in_season?(date) }
  end

  # Compares day and month only, so the window repeats every year. Navidad (Dec 1 to Jan 6) wraps past New Year's.
  def in_season?(date = Date.current)
    return true unless seasonal?
    from = starts_on.change(year: date.year)
    to   = ends_on.change(year: date.year)
    from <= to ? date.between?(from, to) : (date >= from || date <= to)
  end

  def season_label = seasonal? ? "#{starts_on.strftime('%d/%m')} al #{ends_on.strftime('%d/%m')}" : nil
end