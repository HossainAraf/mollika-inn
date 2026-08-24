class BookingCancellationJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    booking = Booking.find_by(id: booking_id)
    return if booking.nil?

    BookingMailer.cancellation_email(booking).deliver_now
  rescue StandardError => e
    Rails.logger.error("[BookingCancellationJob] #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
