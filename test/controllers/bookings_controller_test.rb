require "test_helper"

class BookingsControllerTest < ActionDispatch::IntegrationTest
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
