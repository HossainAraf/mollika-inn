class CreateDiningReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :dining_reservations do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.date :reservation_date
      t.integer :reservation_time
      t.integer :number_of_guests
      t.text :special_requests
      t.string :status

      t.timestamps
    end
  end
end
