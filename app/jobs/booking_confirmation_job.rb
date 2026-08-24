class BookingConfirmationJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    booking = Booking.find_by(id: booking_id)
    return if booking.nil?

    Rails.logger.info("[BookingConfirmationJob] Sending to #{booking.guest.email}")

    message = BookingMailer.confirmation_email(booking)

    BrevoMailer.send_email(
      to: booking.guest.email,
      subject: message.subject,
      html_content: message.body.to_s
    )

    Rails.logger.info(
      "[BookingConfirmationJob] Email sent for booking #{booking.id}"
    )
  end
end
