require "test_helper"

class BookingsControllerTest < ActionDispatch::IntegrationTest
  include AdminAuthTestHelper

  test "admin can create a manual confirmed booking without occupying the room" do
    room_type = RoomType.create!(name: "Deluxe Room", slug: "deluxe-room-manual", base_price_per_night: 5000, max_occupancy: 2)
    room = Room.create!(room_type: room_type, room_number: "201", floor: 2, status: "available")

    login_as_admin

    assert_difference -> { Booking.count }, 1 do
      post admin_bookings_path, params: {
        booking: {
          room_type_id: room_type.id,
          room_number: room.room_number,
          check_in_date: (Date.today + 5).to_s,
          check_out_date: (Date.today + 7).to_s,
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
    assert_equal "confirmed", booking.status
    assert_equal "available", room.reload.status
  end

  test "admin manual confirmed booking blocks overlapping dates" do
    room_type = RoomType.create!(name: "Deluxe Room", slug: "deluxe-room-overlap", base_price_per_night: 5000, max_occupancy: 2)
    room = Room.create!(room_type: room_type, room_number: "202", floor: 2, status: "available")

    login_as_admin

    existing_booking = Booking.create!(
      guest: Guest.create!(first_name: "Existing", last_name: "Guest", email: "existing-#{SecureRandom.hex(4)}@example.com", phone: "+8801712345678", nationality: "Bangladeshi"),
      check_in_date: Date.today + 10,
      check_out_date: Date.today + 12,
      num_adults: 2,
      num_children: 0,
      status: "confirmed",
      payment_status: "unpaid",
      total_amount: 10000
    )
    BookingRoom.create!(booking: existing_booking, room: room, room_type: room_type, rate_per_night: 5000, total_amount: 10000)

    login_as_admin

    assert_no_difference -> { Booking.count } do
      post admin_bookings_path, params: {
        booking: {
          room_type_id: room_type.id,
          room_number: room.room_number,
          check_in_date: (Date.today + 11).to_s,
          check_out_date: (Date.today + 13).to_s,
          num_adults: 2,
          num_children: 0,
          special_requests: "Overlap attempt",
          payment_status: "unpaid",
          total_amount: 10000,
          guest: {
            first_name: "New",
            last_name: "Guest",
            email: "new-overlap@example.com",
            phone: "+8801723456789",
            nationality: "Bangladeshi"
          }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match(/Selected room is not available for the chosen dates\./, response.body)
  end

  test "rerenders the admin booking form with submitted values when guest data is invalid" do
    room_type = RoomType.create!(name: "Deluxe Room", slug: "deluxe-room-form-state", base_price_per_night: 5000, max_occupancy: 2)
    Room.create!(room_type: room_type, room_number: "202", floor: 2, status: "available")

    login_as_admin

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
    assert_select "p", text: /৳\s*5000/
  end

  test "rejects invalid guest fields on booking create" do
    room_type = RoomType.create!(name: "Deluxe Room", slug: "deluxe-room-test", base_price_per_night: 5000, max_occupancy: 2)
    Room.create!(room_type: room_type, room_number: "101", floor: 1, status: "available")

    login_as_admin

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
