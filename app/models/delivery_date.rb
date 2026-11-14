class DeliveryDate < ApplicationRecord
  DAYS   = %w[Domingo Lunes Martes Miércoles Jueves Viernes Sábado].freeze
  MONTHS = %w[_ ene feb mar abr may jun jul ago sep oct nov dic].freeze

  belongs_to :delivery_zone
  has_many :orders, dependent: :restrict_with_error
  validates :date, :cutoff_at, presence: true

  scope :open, -> { where("cutoff_at > ?", Time.current).order(:date) }

  def self.label_for(date) = "#{DAYS[date.wday]} #{date.day} #{MONTHS[date.month]}"
  def label = self.class.label_for(date)           # "Viernes 20 nov"
  def full? = capacity.present? && orders.committed.count >= capacity
end