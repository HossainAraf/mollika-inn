class CreateAvailabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :availabilities do |t|
      t.references :room, null: false, foreign_key: true
      t.date :blocked_date, null: false
      t.string :reason

      t.timestamps
    end

    add_index :availabilities, [ :room_id, :blocked_date ], unique: true
  end
end
