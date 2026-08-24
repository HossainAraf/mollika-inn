class CreateConferenceReservations < ActiveRecord::Migration[7.0]
  def change
    create_table :conference_reservations do |t|
      t.string  :organization_name
      t.string  :contact_name
      t.string  :email
      t.string  :phone
      t.date    :event_date
      t.string  :duration
      t.integer :attendees
      t.string  :package
      t.text    :special_requests
      t.string  :status, default: "pending"

      t.timestamps
    end

    add_index :conference_reservations, :email
    add_index :conference_reservations, :event_date
  end
end
