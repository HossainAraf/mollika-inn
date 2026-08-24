require "minitest/autorun"
require_relative "../../config/environment"

class AdminNotificationJobTest < Minitest::Test
  def test_perform_creates_a_booking_notification
    guest = Guest.create!(first_name: "Test", last_name: "Guest", email: "guest-#{SecureRandom.hex(4)}@example.com", phone: "123456789")
    room_type = RoomType.create!(name: "Suite #{SecureRandom.hex(3)}", max_occupancy: 2, base_price_per_night: 5000)
    room = Room.create!(room_type: room_type, room_number: "R-#{SecureRandom.hex(3)}")

    AdminBookingNotificationJob.singleton_class.send(:define_method, :perform_later) { |_id| true }

    booking = Booking.create!(
      guest: guest,
      check_in_date: Date.current + 7,
      check_out_date: Date.current + 9,
      num_adults: 2,
      num_children: 0,
      status: "pending",
      payment_status: "unpaid",
      total_amount: 10000
    )
    BookingRoom.create!(booking: booking, room: room, room_type: room_type, rate_per_night: 5000, total_amount: 10000)

    before_count = AdminNotification.count
    AdminBookingNotificationJob.perform_now(booking.id)
    after_count = AdminNotification.count

    assert_equal before_count + 1, after_count

    notification = AdminNotification.last
    assert_equal booking.id, notification.booking_id
    assert_equal "booking_created", notification.notification_type
    assert_includes notification.body, guest.full_name
  ensure
    AdminBookingNotificationJob.singleton_class.send(:remove_method, :perform_later)
  end
end
