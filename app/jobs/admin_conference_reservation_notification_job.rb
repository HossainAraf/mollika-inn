class AdminConferenceReservationNotificationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = ConferenceReservation.find_by(id: reservation_id)
    return unless reservation

    notification = AdminNotification.create!(
      booking_id: nil,
      notification_type: "conference_reservation_created",
      title: "New conference reservation",
      body: notification_body(reservation)
    )

    AdminNotification.broadcast_widget!
    notification
  end

  private

  def notification_body(reservation)
    "#{reservation.contact_name} requested a #{reservation.duration.downcase} conference for #{reservation.attendees} guests on #{I18n.l(reservation.event_date, format: :short)}."
  end
end
