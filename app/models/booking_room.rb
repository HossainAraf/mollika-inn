class BookingRoom < ApplicationRecord
  belongs_to :booking
  belongs_to :room
  belongs_to :room_type

  validates :rate_per_night, numericality: { greater_than_or_equal_to: 0 }
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
end
