class CreateMenuItems < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_items do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.string :category
      t.integer :position
      t.boolean :available

      t.timestamps
    end
  end
end
