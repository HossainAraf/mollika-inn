require "test_helper"

class BookingTest < ActiveSupport::TestCase
  test "confirm! falls back to immediate job execution when queue enqueue fails" do
    guest = Guest.create!(first_name: "Ada", last_name: "Lovelace", email: "ada@example.com", phone: "1234567890")
    booking = Booking.create!(
      guest: guest,
      check_in_date: Date.tomorrow,
      check_out_date: Date.tomorrow + 2,
      num_adults: 1,
      total_amount: 250,
      paid_amount: 0,
      payment_status: "unpaid"
    )

    BookingConfirmationJob.stub(:perform_later, ->(*) { raise StandardError, "queue unavailable" }) do
      BookingConfirmationJob.stub(:perform_now, ->(*) { true }) do
        assert_nothing_raised do
          booking.confirm!
        end
      end
    end

    assert_equal "confirmed", booking.reload.status
    assert_not_nil booking.reload.confirmed_at
  end
end
