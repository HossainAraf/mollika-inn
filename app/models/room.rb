class Room < ApplicationRecord
  belongs_to :room_type
  has_many :booking_rooms, dependent: :restrict_with_error
  has_many :availabilities, dependent: :destroy

  STATUSES = %w[available maintenance occupied].freeze

  validates :room_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :available, -> { where(status: "available") }
  scope :ordered, -> { order(:floor, :room_number) }

  def available_on?(date)
    status == "available" && !availabilities.where(blocked_date: date).exists?
  end
end
