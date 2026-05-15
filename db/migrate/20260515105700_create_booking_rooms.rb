class CreateBookingRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :booking_rooms do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true
      t.references :room_type, null: false, foreign_key: true
      t.decimal :rate_per_night, precision: 10, scale: 2
      t.decimal :total_amount, precision: 12, scale: 2

      t.timestamps
    end
  end
end
