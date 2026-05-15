class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.references :room_type, null: false, foreign_key: true
      t.string :room_number, null: false
      t.integer :floor
      t.string :status, null: false, default: "available"
      t.text :notes
      t.timestamps
    end
    add_index :rooms, :room_number, unique: true
  end
end
