class BookingConfirmationJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    Rails.logger.warn("[BookingConfirmationJob] START #{booking_id}")

    booking = Booking.find_by(id: booking_id)
    return Rails.logger.warn("[BookingConfirmationJob] Booking not found") if booking.nil?

    Rails.logger.warn("[BookingConfirmationJob] Sending to #{booking.guest.email}")

    BookingMailer.confirmation_email(booking).deliver_now

    Rails.logger.warn("[BookingConfirmationJob] SUCCESS #{booking_id}")
  rescue => e
    Rails.logger.error("[BookingConfirmationJob] ERROR: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end