class Booking < ApplicationRecord
  belongs_to :guest
  has_many :booking_rooms, dependent: :destroy
  has_many :rooms, through: :booking_rooms
  has_many :room_types, through: :booking_rooms
  has_many :reviews, dependent: :nullify

  STATUSES = %w[pending confirmed checked_in checked_out cancelled].freeze
  PAYMENT_STATUSES = %w[unpaid partial paid refunded].freeze

  validates :check_in_date, :check_out_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }
  validates :num_adults, numericality: { greater_than: 0 }
  validate :check_out_after_check_in

  scope :pending,      -> { where(status: "pending") }
  scope :confirmed,    -> { where(status: "confirmed") }
  scope :checked_in,   -> { where(status: "checked_in") }
  scope :checked_out,  -> { where(status: "checked_out") }
  scope :cancelled,    -> { where(status: "cancelled") }
  scope :active,       -> { where(status: %w[confirmed checked_in]) }
  scope :today_arrivals,    -> { confirmed.where(check_in_date: Date.today) }
  scope :today_departures,  -> { checked_in.where(check_out_date: Date.today) }

  def nights
    (check_out_date - check_in_date).to_i
  end

  def confirm!
    update!(status: "confirmed", confirmed_at: Time.current)
    BookingConfirmationJob.perform_later(id)
  end

  def check_in!
    update!(status: "checked_in")
    rooms.each { |r| r.update!(status: "occupied") }
  end

  def check_out!
    update!(status: "checked_out")
    rooms.each { |r| r.update!(status: "available") }
  end

  def cancel!(reason: nil)
    update!(status: "cancelled", cancellation_reason: reason, cancelled_at: Time.current)
    rooms.each { |r| r.update!(status: "available") }
    BookingCancellationJob.perform_later(id)
  end

  def balance_due
    (total_amount || 0) - (paid_amount || 0)
  end

  private

  def check_out_after_check_in
    return unless check_in_date && check_out_date
    errors.add(:check_out_date, "must be after check-in date") if check_out_date <= check_in_date
  end
end
