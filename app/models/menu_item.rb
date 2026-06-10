class MenuItem < ApplicationRecord
  CATEGORIES = %w[bengali continental beverages desserts appetizers].freeze

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  scope :available, -> { where(available: true) }
  scope :by_category, -> { order(:category, :position, :name) }
  scope :ordered, -> { order(:position, :name) }
end
