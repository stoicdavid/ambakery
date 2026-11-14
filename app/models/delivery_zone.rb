class DeliveryZone < ApplicationRecord
  has_many :delivery_dates, dependent: :destroy
  validates :name, presence: true
  scope :available, -> { where(active: true).order(:position) }
end