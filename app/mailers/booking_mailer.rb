class BookingMailer < ApplicationMailer
  def confirmation_email(booking)
    @booking = booking

    mail to: @booking.guest.email,
         subject: "Booking Confirmation ##{@booking.id}"
  end

  def cancellation_email(booking)
    @booking = booking

    mail to: @booking.guest.email,
         subject: "Booking Cancellation ##{@booking.id}"
  end

  def reminder_email(booking)
    @booking = booking

    mail to: @booking.guest.email,
         subject: "Booking Reminder — ##{@booking.id}"
  end
end
