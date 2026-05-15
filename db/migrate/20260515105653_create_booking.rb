class CreateBooking < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :guest, null: false, foreign_key: true
      t.date :check_in_date, null: false
      t.date :check_out_date, null: false
      t.integer :num_adults, default: 1
      t.integer :num_children, default: 0
      t.string :status, default: "pending"
      t.decimal :total_amount, precision: 12, scale: 2
      t.decimal :paid_amount, precision: 12, scale: 2, default: 0
      t.string :payment_status, default: "unpaid"
      t.string :payment_method
      t.string :stripe_payment_intent_id
      t.text :special_requests
      t.text :cancellation_reason
      t.datetime :confirmed_at
      t.datetime :cancelled_at
      t.timestamps
    end
  end
end
