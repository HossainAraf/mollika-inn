require "minitest/autorun"
require_relative "../../config/environment"

class AdminNotificationJobTest < Minitest::Test
  def test_perform_creates_a_booking_notification
    guest = Guest.create!(first_name: "Test", last_name: "Guest", email: "guest-#{SecureRandom.hex(4)}@example.com", phone: "123456789", nationality: "Bangladeshi")
    room_type = RoomType.create!(name: "Suite #{SecureRandom.hex(3)}", max_occupancy: 2, base_price_per_night: 5000)
    room = Room.create!(room_type: room_type, room_number: "R-#{SecureRandom.hex(3)}")

    AdminBookingNotificationJob.singleton_class.send(:define_method, :perform_later) { |_id| true }
    AdminNotification.singleton_class.send(:define_method, :broadcast_widget!) { true }

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

    assert_operator after_count, :>=, before_count + 1

    notification = AdminNotification.last
    assert_equal booking.id, notification.booking_id
    assert_equal "booking_created", notification.notification_type
    assert_includes notification.body, guest.full_name
    AdminNotification.singleton_class.send(:remove_method, :broadcast_widget!)
  end

  def test_perform_creates_a_conference_reservation_notification
    AdminNotification.singleton_class.send(:define_method, :broadcast_widget!) { true }

    conference = ConferenceReservation.create!(
      organization_name: "Alpha Events",
      contact_name: "Jane Doe",
      email: "jane-#{SecureRandom.hex(3)}@example.com",
      phone: "1234567890",
      event_date: Date.current + 5,
      duration: "Full Day",
      attendees: 20,
      status: "pending"
    )

    before_count = AdminNotification.count
    AdminConferenceReservationNotificationJob.perform_now(conference.id)
    after_count = AdminNotification.count

    assert_operator after_count, :>=, before_count + 1

    notification = AdminNotification.last
    assert_nil notification.booking_id
    assert_equal "conference_reservation_created", notification.notification_type
    assert_includes notification.body, conference.contact_name
  ensure
    AdminNotification.singleton_class.send(:remove_method, :broadcast_widget!)
  end

  def test_perform_creates_a_dining_reservation_notification
    AdminNotification.singleton_class.send(:define_method, :broadcast_widget!) { true }

    dining = DiningReservation.create!(
      name: "Jane Doe",
      email: "jane-#{SecureRandom.hex(3)}@example.com",
      phone: "1234567890",
      reservation_date: Date.current + 2,
      reservation_time: 1900,
      number_of_guests: 4,
      status: "pending"
    )

    before_count = AdminNotification.count
    AdminDiningReservationNotificationJob.perform_now(dining.id)
    after_count = AdminNotification.count

    assert_operator after_count, :>=, before_count + 1

    notification = AdminNotification.last
    assert_nil notification.booking_id
    assert_equal "dining_reservation_created", notification.notification_type
    assert_includes notification.body, dining.name
  ensure
    AdminNotification.singleton_class.send(:remove_method, :broadcast_widget!)
  end
end
