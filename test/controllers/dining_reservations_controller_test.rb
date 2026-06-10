require "test_helper"

class DiningReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get dining_reservations_new_url
    assert_response :success
  end

  test "should get create" do
    get dining_reservations_create_url
    assert_response :success
  end

  test "should get show" do
    get dining_reservations_show_url
    assert_response :success
  end
end
