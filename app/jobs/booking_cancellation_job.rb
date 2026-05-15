class BookingCancellationJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    booking = Booking.find_by(id: booking_id)
    return if booking.nil?

    BookingMailer.cancellation_email(booking).deliver_later
  end
end
