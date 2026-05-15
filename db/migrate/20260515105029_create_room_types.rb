class CreateRoomTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :room_types do |t|
    t.string :name, null: false
    t.string :slug, null: false, index: { unique: true }
    t.text :description
    t.integer :max_occupancy, null: false
    t.string :bed_type
    t.integer :size_sqm
    t.decimal :base_price_per_night, precision: 10, scale: 2
    t.jsonb :amenities, default: {}
    t.timestamps
    end
  end
end
