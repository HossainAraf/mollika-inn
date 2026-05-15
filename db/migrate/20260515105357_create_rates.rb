class CreateRates < ActiveRecord::Migration[8.1]
  def change
    create_table :rates do |t|
      t.references :room_type, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :price_per_night, precision: 10, scale: 2, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :day_of_week
      t.integer :priority, default: 0
      t.timestamps
    end
  end
end
