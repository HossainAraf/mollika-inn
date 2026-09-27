require "test_helper"

class RoomTest < Minitest::Test
  def test_room_statuses_are_limited_to_physical_operating_states
    assert_equal %w[available maintenance occupied], Room::STATUSES
    refute_includes Room::STATUSES, "reserved"
    assert_empty Room.where(status: "reserved")
  end

  def test_available_occupied_and_maintenance_are_valid_persisted_room_statuses
    %w[available occupied maintenance].each do |status|
      assert_includes Room::STATUSES, status
    end
  end
end
