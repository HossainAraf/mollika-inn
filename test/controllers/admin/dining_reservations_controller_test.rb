require "test_helper"

class Admin::DiningReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_dining_reservations_index_url
    assert_response :success
  end

  test "should get show" do
    get admin_dining_reservations_show_url
    assert_response :success
  end
end
