class CreateFacilities < ActiveRecord::Migration[8.0]
  def change
    create_table :facilities do |t|
      t.string :name, null: false
      t.text :description
      t.string :icon_name
      t.string :category
      t.integer :position, default: 0
      t.boolean :visible, default: true

      t.timestamps
    end
  end
end
