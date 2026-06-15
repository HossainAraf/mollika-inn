class AddIndexesForPerformance < ActiveRecord::Migration[8.1]
  def change
    # Bookings indexes for common queries
    add_index :bookings, :status unless index_exists?(:bookings, :status)
    add_index :bookings, :check_in_date unless index_exists?(:bookings, :check_in_date)
    add_index :bookings, :check_out_date unless index_exists?(:bookings, :check_out_date)
    add_index :bookings, :guest_id unless index_exists?(:bookings, :guest_id)
    add_index :bookings, [:status, :check_in_date] unless index_exists?(:bookings, [:status, :check_in_date])

    # Rooms indexes
    add_index :rooms, :status unless index_exists?(:rooms, :status)
    add_index :rooms, :room_type_id unless index_exists?(:rooms, :room_type_id)

    # Reviews indexes
    add_index :reviews, :approved unless index_exists?(:reviews, :approved)
    add_index :reviews, :created_at unless index_exists?(:reviews, :created_at)

    # Guests indexes
    add_index :guests, :email unless index_exists?(:guests, :email)

    # Facilities indexes
    add_index :facilities, :category unless index_exists?(:facilities, :category)
    add_index :facilities, :visible unless index_exists?(:facilities, :visible)
    add_index :facilities, [:category, :visible] unless index_exists?(:facilities, [:category, :visible])

    # MenuItems indexes
    add_index :menu_items, :category unless index_exists?(:menu_items, :category)
    add_index :menu_items, :available unless index_exists?(:menu_items, :available)
    add_index :menu_items, [:category, :available] unless index_exists?(:menu_items, [:category, :available])

    # DiningReservations indexes
    add_index :dining_reservations, :status unless index_exists?(:dining_reservations, :status)
    add_index :dining_reservations, :reservation_date unless index_exists?(:dining_reservations, :reservation_date)
    add_index :dining_reservations, [:status, :reservation_date] unless index_exists?(:dining_reservations, [:status, :reservation_date])
  end
end
