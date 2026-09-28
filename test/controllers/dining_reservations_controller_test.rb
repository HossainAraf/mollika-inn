require "test_helper"

class DiningReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_dining_reservation_path

    assert_response :success
  end

  test "should create dining reservation" do
    assert_difference("DiningReservation.count", 1) do
      post dining_reservations_path, params: {
        dining_reservation: {
          name: "Test Guest",
          email: "test@example.com",
          phone: "+8801712345678",
          reservation_date: Date.tomorrow,
          reservation_time: 1900,
          number_of_guests: 2
        }
      }
    end

    reservation = DiningReservation.order(:id).last

    assert_redirected_to dining_reservation_path(reservation)
    assert_equal "pending", reservation.status
  end

  test "should get show" do
    reservation = DiningReservation.create!(
      name: "Test Guest",
      email: "test@example.com",
      phone: "+8801712345678",
      reservation_date: Date.tomorrow,
      reservation_time: 1900,
      number_of_guests: 2
    )

    get dining_reservation_path(reservation)

    assert_response :success
  end
end
