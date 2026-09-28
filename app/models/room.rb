class Room < ApplicationRecord
  belongs_to :room_type
  has_many :booking_rooms, dependent: :restrict_with_error
  has_many :bookings, through: :booking_rooms
  has_many :availabilities, dependent: :destroy
  has_many :active_bookings, -> { where(status: %w[confirmed checked_in]).order(:check_in_date) }, through: :booking_rooms, source: :booking

  STATUSES = %w[available maintenance occupied].freeze

  validates :room_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :available, -> { where(status: "available") }
  scope :ordered, -> { order(:floor, :room_number) }

  def available_on?(date)
    status == "available" && !availabilities.where(blocked_date: date).exists?
  end

  def bookable_for?(booking = nil)
    return false if status == "maintenance"
    return true if status == "available"
    return false unless status == "occupied"
    return false if booking.blank? || !booking.persisted?

    booking.status == "checked_in" &&
      booking.booking_rooms.exists?(room_id: id)
  end

  def available_between?(check_in, check_out)
  return false if check_in.blank? || check_out.blank?
  return false if check_out <= check_in
  return false unless status == "available"

  blocked = availabilities
    .where(blocked_date: check_in...check_out)
    .exists?

  return false if blocked

  !bookings
    .room_reserving
    .where(
      "check_in_date < ? AND check_out_date > ?",
      check_out,
      check_in
    )
    .exists?
  end
end
