require "test_helper"

class Admin::DiningReservationsControllerTest < ActionDispatch::IntegrationTest
  include AdminAuthTestHelper

  setup do
    login_as_admin
  end

  test "should get index" do
    get admin_dining_reservations_path

    assert_response :success
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

    get admin_dining_reservation_path(reservation)

    assert_response :success
  end
end
