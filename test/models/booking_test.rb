require "minitest/autorun"
require_relative "../../config/environment"

class BookingTest < Minitest::Test
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
end
