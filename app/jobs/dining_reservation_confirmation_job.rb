class DiningReservationConfirmationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = DiningReservation.find_by(id: reservation_id)
    return if reservation.nil?

    Rails.logger.info("[DiningReservationConfirmationJob] Sending to #{reservation.email}")

    subject = "Dining Reservation Confirmation ##{reservation.id}"
    html_content = <<~HTML
      <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #1f2937;">
        <h2 style="color: #0f172a;">Table reservation received</h2>
        <p>Thank you for choosing Mollika Inn. We have received your dining reservation request.</p>
        <p><strong>Reservation ID:</strong> ##{reservation.id}</p>
        <p><strong>Name:</strong> #{ERB::Util.html_escape(reservation.name)}</p>
        <p><strong>Email:</strong> #{ERB::Util.html_escape(reservation.email)}</p>
        <p><strong>Phone:</strong> #{ERB::Util.html_escape(reservation.phone)}</p>
        <p><strong>Date:</strong> #{reservation.reservation_date}</p>
        <p><strong>Time:</strong> #{reservation.reservation_time.to_s.rjust(4, '0').insert(2, ':')}</p>
        <p><strong>Guests:</strong> #{reservation.number_of_guests}</p>
        <p>We will contact you shortly to confirm the request.</p>
      </div>
    HTML

    BrevoMailer.send_email(
      to: reservation.email,
      subject: subject,
      html_content: html_content
    )

    Rails.logger.info(
      "[DiningReservationConfirmationJob] Email sent for dining reservation #{reservation.id}"
    )
  end
end
