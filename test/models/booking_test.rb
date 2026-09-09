require "minitest/autorun"
require_relative "../../config/environment"
require "securerandom"

class BookingTest < Minitest::Test
  def test_confirm_marks_booking_room_occupied
    booking, room = build_booking_with_room

    booking.confirm!

    assert_equal "occupied", room.reload.status
    assert_equal "confirmed", booking.reload.status
  end

  def test_available_rooms_count_ignores_occupied_rooms
    room_type = create_room_type
    occupied_room = Room.create!(room_type: room_type, room_number: unique_room_number, floor: 1, status: "available")
    Room.create!(room_type: room_type, room_number: unique_room_number, floor: 1, status: "available")

    booking = Booking.create!(
      guest: Guest.create!(
        first_name: "Test",
        last_name: "Guest",
        email: "guest-#{SecureRandom.hex(4)}@example.com",
        phone: "+8801712345678",
        nationality: "Bangladeshi"
      ),
      check_in_date: Date.current + 1,
      check_out_date: Date.current + 2,
      num_adults: 1,
      num_children: 0,
      status: "pending",
      payment_status: "unpaid"
    )

    BookingRoom.create!(
      booking: booking,
      room: occupied_room,
      room_type: room_type,
      rate_per_night: 100,
      total_amount: 100
    )

    booking.confirm!

    assert_equal 1, room_type.available_rooms_count(Date.current, Date.current + 1)
  end

  def test_confirm_falls_back_to_immediate_job_execution_when_queue_enqueue_fails
    booking = Booking.new
    booking.define_singleton_method(:update!) { |**_attrs| true }

    calls = []
    BookingConfirmationJob.singleton_class.send(:define_method, :perform_later) { |_id| raise StandardError, "queue unavailable" }
    BookingConfirmationJob.singleton_class.send(:define_method, :perform_now) { |id| calls << id; true }

    booking.confirm!

    assert_equal [ booking.id ], calls
  end

  def test_enqueue_admin_booking_notification_job_delegates_to_job
    booking = Booking.new(id: 123)
    calls = []

    AdminBookingNotificationJob.singleton_class.send(:define_method, :perform_later) { |id| calls << id; true }

    booking.send(:enqueue_admin_booking_notification_job)

    assert_equal [ 123 ], calls
  end

  private

  def build_booking_with_room
    room_type = create_room_type
    room = Room.create!(room_type: room_type, room_number: unique_room_number, floor: 2, status: "available")
    booking = Booking.create!(
      guest: Guest.create!(
        first_name: "Test",
        last_name: "Guest",
        email: "booking-#{SecureRandom.hex(4)}@example.com",
        phone: "+8801712345678",
        nationality: "Bangladeshi"
      ),
      check_in_date: Date.current + 1,
      check_out_date: Date.current + 2,
      num_adults: 1,
      num_children: 0,
      status: "pending",
      payment_status: "unpaid"
    )

    BookingRoom.create!(
      booking: booking,
      room: room,
      room_type: room_type,
      rate_per_night: 100,
      total_amount: 100
    )

    [ booking, room ]
  end

  def create_room_type
    RoomType.create!(
      name: "Test Room Type #{SecureRandom.hex(4)}",
      slug: "test-room-type-#{SecureRandom.hex(4)}",
      base_price_per_night: 100,
      max_occupancy: 2
    )
  end

  def unique_room_number
    "R#{SecureRandom.hex(4)}"
  end
end
