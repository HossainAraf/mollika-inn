class AddGuestNameToBookings < ActiveRecord::Migration[8.1]
  def up
    add_column :bookings, :guest_name, :string, default: "", null: false

    Booking.reset_column_information
    Booking.includes(:guest).find_each do |booking|
      booking.update_columns(guest_name: booking.guest&.full_name.to_s)
    end
  end

  def down
    remove_column :bookings, :guest_name
  end
end
