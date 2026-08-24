class Facility < ApplicationRecord
  CATEGORIES = %w[comfort services connectivity amenities safety dining].freeze

  validates :name, presence: true
  # validates :category, inclusion: { in: CATEGORIES }, allow_blank: true

  # scope :visible, -> { where(visible: true) }
  # Replace the visible scope with this:
  scope :visible, -> { all }  # Returns all records since no visible column
  scope :ordered, -> { order(:position, :name) }
  scope :by_category, -> { order(:category, :position) }
end
