class ConferenceReservationConfirmationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = ConferenceReservation.find_by(id: reservation_id)
    return if reservation.nil?

    Rails.logger.info("[ConferenceReservationConfirmationJob] Sending to #{reservation.email}")

    subject = "Conference Reservation Confirmation ##{reservation.id}"
    html_content = <<~HTML
      <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #1f2937;">
        <h2 style="color: #0f172a;">Conference reservation confirmed</h2>
        <p>Thank you for your interest in hosting your event with Mollika Inn.</p>
        <p><strong>Reservation ID:</strong> ##{reservation.id}</p>
        <p><strong>Organization:</strong> #{ERB::Util.html_escape(reservation.organization_name.to_s)}</p>
        <p><strong>Contact:</strong> #{ERB::Util.html_escape(reservation.contact_name)}</p>
        <p><strong>Email:</strong> #{ERB::Util.html_escape(reservation.email)}</p>
        <p><strong>Event Date:</strong> #{reservation.event_date}</p>
        <p><strong>Duration:</strong> #{ERB::Util.html_escape(reservation.duration.to_s)}</p>
        <p><strong>Attendees:</strong> #{reservation.attendees}</p>
        <p>We will contact you shortly to finalize the event details.</p>
      </div>
    HTML

    BrevoMailer.send_email(
      to: reservation.email,
      subject: subject,
      html_content: html_content
    )

    Rails.logger.info(
      "[ConferenceReservationConfirmationJob] Email sent for conference reservation #{reservation.id}"
    )
  end
end
