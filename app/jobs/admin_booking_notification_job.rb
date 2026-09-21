class AdminBookingNotificationJob < ApplicationJob
  queue_as :default

  def perform(booking_id, notification_type = "booking_created")
    booking = Booking.includes(:guest, booking_rooms: :room_type).find_by(id: booking_id)
    return unless booking

    notification = AdminNotification.find_or_initialize_by(
      booking_id: booking.id,
      notification_type: notification_type
    )

    attrs = notification_attributes_for(booking, notification_type)
    notification.assign_attributes(attrs)
    return unless notification.new_record? || notification.changed?

    notification.save!
    AdminNotification.broadcast_widget!
  end

  private

  def notification_body(booking)
    room_name = booking.booking_rooms.first&.room_type&.name || "room"
    check_in = I18n.l(booking.check_in_date, format: :short)
    check_out = I18n.l(booking.check_out_date, format: :short)

    "#{booking.display_guest_name} booked #{room_name} from #{check_in} to #{check_out}."
  end

  def notification_attributes_for(booking, notification_type)
    case notification_type
    when "booking_created"
      {
        title: "New booking received",
        body: notification_body(booking)
      }
    when "booking_updated"
      {
        title: "Booking updated",
        body: "#{booking.display_guest_name} booking was updated. Current status: #{booking.status.titleize}."
      }
    else
      {
        title: "Booking activity",
        body: notification_body(booking)
      }
    end
  end
end
