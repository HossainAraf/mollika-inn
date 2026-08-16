class BookingMailer < ApplicationMailer
  def confirmation_email(booking)
    @booking = booking

    mail to: @booking.guest.email,
         subject: "Booking Confirmation ##{@booking.id}"
  end
end
