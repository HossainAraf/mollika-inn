class BookingConfirmationJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    booking = Booking.find_by(id: booking_id)
    return if booking.nil?

    BookingMailer.confirmation_email(booking).deliver_now
  rescue StandardError => e
    Rails.logger.error("[BookingConfirmationJob] #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
