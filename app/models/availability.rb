class Availability < ApplicationRecord
  belongs_to :room

  validates :blocked_date, presence: true
  validates :blocked_date, uniqueness: { scope: :room_id, message: "is already blocked for this room" }
end
