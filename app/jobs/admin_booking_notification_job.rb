class AdminBookingNotificationJob < ApplicationJob
  queue_as :default

  def perform(booking_id)
    booking = Booking.includes(:guest, booking_rooms: :room_type).find_by(id: booking_id)
    return unless booking

    notification = AdminNotification.find_or_initialize_by(
      booking_id: booking.id,
      notification_type: "booking_created"
    )

    notification.assign_attributes(
      title: "New booking received",
      body: notification_body(booking)
    )
    notification.save! if notification.new_record? || notification.changed?
  end

  private

  def notification_body(booking)
    room_name = booking.booking_rooms.first&.room_type&.name || "room"
    check_in = I18n.l(booking.check_in_date, format: :short)
    check_out = I18n.l(booking.check_out_date, format: :short)

    "#{booking.display_guest_name} booked #{room_name} from #{check_in} to #{check_out}."
  end
end
