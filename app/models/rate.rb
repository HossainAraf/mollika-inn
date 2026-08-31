class Rate < ApplicationRecord
  belongs_to :room_type

  validates :name, :price_per_night, :start_date, :end_date, presence: true
  validates :price_per_night, numericality: { greater_than: 0 }
  validate :end_date_after_start_date

  scope :ordered, -> { order(priority: :desc, start_date: :asc) }

  private

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end

  after_commit :propagate_room_type_update, on: [ :create, :update, :destroy ]

  def propagate_room_type_update
    room_type.update_future_bookings
  rescue StandardError => e
    Rails.logger.error("[Rate] propagate_room_type_update failed for rate #{id}: #{e.message}")
  end
end
