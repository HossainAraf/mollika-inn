class BookingConfirmationJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, wait: 10.seconds, attempts: 5

  def perform(booking_id)
    booking = Booking.find_by(id: booking_id)
    return if booking.nil?

    BookingMailer.confirmation_email(booking).deliver_now
  end
end