class AdminDiningReservationNotificationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = DiningReservation.find_by(id: reservation_id)
    return unless reservation

    notification = AdminNotification.create!(
      booking_id: nil,
      notification_type: "dining_reservation_created",
      title: "New dining reservation",
      body: notification_body(reservation)
    )

    AdminNotification.broadcast_widget!
    notification
  end

  private

  def notification_body(reservation)
    reservation_time = reservation.reservation_time.to_s.rjust(4, "0")
    formatted_time = reservation_time[0..1] + ":" + reservation_time[2..3]

    "#{reservation.name} requested a table for #{reservation.number_of_guests} guests on #{I18n.l(reservation.reservation_date, format: :short)} at #{formatted_time}."
  end
end
