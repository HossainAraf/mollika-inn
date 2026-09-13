require "test_helper"

class BookingsControllerTest < ActionDispatch::IntegrationTest
  self.fixture_paths = []
  self.fixture_table_names = []

  setup do
    @original_forgery_protection = ActionController::Base.allow_forgery_protection
    @original_admin_email = ENV["ADMIN_EMAIL"]
    @original_admin_password = ENV["ADMIN_PASSWORD"]
    ENV["ADMIN_EMAIL"] = "admin@mollika.com"
    ENV["ADMIN_PASSWORD"] = "mollika2026"

    ActionController::Base.allow_forgery_protection = false

    post session_path, params: { email: ENV["ADMIN_EMAIL"], password: ENV["ADMIN_PASSWORD"] }
    assert_redirected_to admin_root_path
  end

  teardown do
    ENV["ADMIN_EMAIL"] = @original_admin_email
    ENV["ADMIN_PASSWORD"] = @original_admin_password
    ActionController::Base.allow_forgery_protection = @original_forgery_protection
  end

  test "admin can create a manual walk-in booking" do
    room_type = RoomType.create!(name: "Deluxe Room", slug: "deluxe-room-manual", base_price_per_night: 5000, max_occupancy: 2)
    Room.create!(room_type: room_type, room_number: "201", floor: 2, status: "available")

    assert_difference -> { Booking.count }, 1 do
      post admin_bookings_path, params: {
        booking: {
          room_type_id: room_type.id,
          check_in_date: Date.today.to_s,
          check_out_date: (Date.today + 1).to_s,
          num_adults: 2,
          num_children: 0,
          special_requests: "Walk-in guest arrival.",
          payment_status: "unpaid",
          total_amount: 5000,
          guest: {
            first_name: "Walk",
            last_name: "In",
            email: "walkin@example.com",
            phone: "+8801723456789",
            nationality: "Bangladeshi"
          }
        }
      }
    end

    booking = Booking.order(:created_at).last
    assert_redirected_to admin_booking_path(booking)
    assert_equal "Walk In", booking.display_guest_name
    assert_equal "pending", booking.status
  end

  test "rerenders the admin booking form with submitted values when guest data is invalid" do
    room_type = RoomType.create!(name: "Deluxe Room", slug: "deluxe-room-form-state", base_price_per_night: 5000, max_occupancy: 2)
    Room.create!(room_type: room_type, room_number: "202", floor: 2, status: "available")

    assert_no_difference -> { Booking.count } do
      post admin_bookings_path, params: {
        booking: {
          room_type_id: room_type.id,
          check_in_date: Date.today.to_s,
          check_out_date: (Date.today + 1).to_s,
          num_adults: 2,
          num_children: 0,
          special_requests: "Walk-in guest arrival.",
          payment_status: "unpaid",
          total_amount: 5000,
          guest: {
            first_name: "",
            last_name: "",
            email: "",
            phone: "",
            nationality: ""
          }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "select[name='booking[room_type_id]'] option[selected][value='#{room_type.id}']"
    assert_select "input[name='booking[check_in_date]'][value='#{Date.today}']"
    assert_select "input[name='booking[check_out_date]'][value='#{(Date.today + 1)}']"
    assert_select "input[name='booking[amount_paid]']"
  end

  test "admin booking form shows only available room numbers for the selected room type" do
    room_type = RoomType.create!(name: "Deluxe Room", slug: "deluxe-room-dropdown", base_price_per_night: 5000, max_occupancy: 2)
    Room.create!(room_type: room_type, room_number: "301", floor: 3, status: "occupied")
    available_room = Room.create!(room_type: room_type, room_number: "302", floor: 3, status: "available")

    get new_admin_booking_path, params: {
      calculate_price: "1",
      booking: {
        room_type_id: room_type.id,
        room_number: available_room.room_number,
        check_in_date: Date.today.to_s,
        check_out_date: (Date.today + 1).to_s,
        num_adults: 2,
        num_children: 0,
        payment_status: "unpaid"
      }
    }

    assert_response :success
    assert_select "select[name='booking[room_number]'] option[value='302']"
    assert_select "select[name='booking[room_number]'] option[value='301']", false
    assert_select "p.text-rose-600", text: /No available rooms found/, count: 0
  end

  test "admin booking form shows a message when no rooms are available for the selected room type" do
    room_type = RoomType.create!(name: "Deluxe Room", slug: "deluxe-room-none", base_price_per_night: 5000, max_occupancy: 2)
    Room.create!(room_type: room_type, room_number: "401", floor: 4, status: "occupied")

    get new_admin_booking_path, params: {
      calculate_price: "1",
      booking: {
        room_type_id: room_type.id,
        check_in_date: Date.today.to_s,
        check_out_date: (Date.today + 1).to_s,
        num_adults: 2,
        num_children: 0,
        payment_status: "unpaid"
      }
    }

    assert_response :success
    assert_select "p.text-rose-600", text: /No available rooms found for this room type on the selected dates./
    assert_select "select[name='booking[room_number]'][disabled]"
  end

  test "rejects invalid guest fields on booking create" do
    room_type = RoomType.create!(name: "Deluxe Room", slug: "deluxe-room-test", base_price_per_night: 5000, max_occupancy: 2)
    Room.create!(room_type: room_type, room_number: "101", floor: 1, status: "available")

    assert_no_difference -> { Booking.count } do
      post bookings_path(room_type_slug: room_type.slug), params: {
        booking: {
          check_in_date: Date.today.to_s,
          check_out_date: (Date.today + 1).to_s,
          num_adults: 1,
          num_children: 0,
          special_requests: "",
          guest: {
            first_name: "John1",
            last_name: "Doe",
            email: "john@example.com",
            phone: "abc123",
            nationality: "Bangladeshi1"
          }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".text-red-700", text: /only allows letters|only allows digits/
  end

  test "allows repeat email with a different valid name without updating the existing guest" do
    room_type = RoomType.create!(name: "Deluxe Room", slug: "deluxe-room-test-2", base_price_per_night: 5000, max_occupancy: 2)
    Room.create!(room_type: room_type, room_number: "102", floor: 1, status: "available")
    existing_guest = Guest.create!(
      first_name: "Old",
      last_name: "Name",
      email: "father@example.com",
      phone: "+8801712345678",
      nationality: "Bangladeshi"
    )

    assert_difference -> { Booking.count }, 1 do
      post bookings_path(room_type_slug: room_type.slug), params: {
        booking: {
          check_in_date: Date.today.to_s,
          check_out_date: (Date.today + 1).to_s,
          num_adults: 1,
          num_children: 0,
          special_requests: "",
          guest: {
            first_name: "New",
            last_name: "Guest",
            email: existing_guest.email,
            phone: existing_guest.phone,
            nationality: existing_guest.nationality
          }
        }
      }
    end

    existing_guest.reload
    assert_equal "Old", existing_guest.first_name
    assert_equal "Name", existing_guest.last_name

    booking = Booking.order(:created_at).last
    assert_equal "New Guest", booking.guest_name
  end
end
