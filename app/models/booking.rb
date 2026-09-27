class Booking < ApplicationRecord
  belongs_to :guest
  has_many :booking_rooms, dependent: :destroy
  has_many :rooms, through: :booking_rooms
  has_many :room_types, through: :booking_rooms
  has_many :reviews, dependent: :nullify

  after_create_commit :enqueue_admin_booking_notification_job
  after_update_commit :enqueue_admin_booking_update_notification_job, if: :should_enqueue_admin_booking_update_notification?

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
  scope :room_reserving, -> { where(status: %w[pending confirmed checked_in]) }
  scope :today_arrivals,    -> { confirmed.where(check_in_date: Date.today) }
  scope :today_departures,  -> { checked_in.where(check_out_date: Date.today) }

  def nights
    (check_out_date - check_in_date).to_i
  end

  def confirm!
    transaction do
      update!(status: "confirmed", confirmed_at: Time.current)
    end

    enqueue_confirmation_job
    schedule_reminder_job
  end

  def check_in!
    transaction do
      update!(status: "checked_in")
      rooms.each { |r| r.update!(status: "occupied") }
    end
  end

  def check_out!
    transaction do
      update!(status: "checked_out")
      rooms.each { |r| r.update!(status: "available") }
    end
  end

  def cancel!(reason: nil)
    unless %w[pending confirmed].include?(status)
      errors.add(:status, "cannot be cancelled from #{status}")
      raise ActiveRecord::RecordInvalid.new(self)
    end

    transaction do
      update!(status: "cancelled", cancellation_reason: reason, cancelled_at: Time.current)
    end

    enqueue_cancellation_job
  end

  def balance_due
    (total_amount || 0) - (paid_amount || 0)
  end

  def display_guest_name
    guest_name.presence || guest&.full_name || "—"
  end

  private

  def enqueue_confirmation_job
    BookingConfirmationJob.perform_later(id)
  rescue StandardError => e
    Rails.logger.error("[Booking] confirmation job enqueue failed: #{e.message}")
    BookingConfirmationJob.perform_now(id)
  end

  def enqueue_cancellation_job
    BookingCancellationJob.perform_later(id)
  rescue StandardError => e
    Rails.logger.error("[Booking] cancellation job enqueue failed: #{e.message}")
    BookingCancellationJob.perform_now(id)
  end

  def schedule_reminder_job
    return unless check_in_date

    reminder_date = check_in_date - 1.day
    # schedule at 09:00 local time on the reminder date
    reminder_time = Time.zone.local(reminder_date.year, reminder_date.month, reminder_date.day, 9, 0, 0)

    if reminder_time > Time.zone.now
      BookingReminderJob.set(wait_until: reminder_time).perform_later(id)
      Rails.logger.info("[Booking] Scheduled reminder for booking #{id} at #{reminder_time}")
    else
      Rails.logger.info("[Booking] Skipped scheduling reminder for booking #{id} — reminder_time in past")
    end
  rescue StandardError => e
    Rails.logger.error("[Booking] reminder scheduling failed for booking #{id}: #{e.message}")
  end

  def check_out_after_check_in
    return unless check_in_date && check_out_date
    errors.add(:check_out_date, "must be after check-in date") if check_out_date <= check_in_date
  end

  def enqueue_admin_booking_notification_job
    return if Thread.current[:suppress_admin_booking_notifications]

    AdminBookingNotificationJob.perform_later(id)
  rescue StandardError => e
    Rails.logger.error("[Booking] admin notification job enqueue failed: #{e.message}")
    AdminBookingNotificationJob.perform_now(id)
  end

  def enqueue_admin_booking_update_notification_job
    return if Thread.current[:suppress_admin_booking_notifications]

    AdminBookingNotificationJob.perform_later(id, "booking_updated")
  rescue StandardError => e
    Rails.logger.error("[Booking] admin update notification failed: #{e.message}")
    # Fallback to the job if creation fails
    AdminBookingNotificationJob.perform_now(id, "booking_updated")
  end

  def should_enqueue_admin_booking_update_notification?
    return false if Thread.current[:suppress_admin_booking_notifications]

    saved_change_to_status? ||
      saved_change_to_check_in_date? ||
      saved_change_to_check_out_date? ||
      saved_change_to_num_adults? ||
      saved_change_to_num_children? ||
      saved_change_to_special_requests? ||
      saved_change_to_guest_name? ||
      saved_change_to_payment_status? ||
      saved_change_to_paid_amount? ||
      saved_change_to_total_amount?
  end
end
