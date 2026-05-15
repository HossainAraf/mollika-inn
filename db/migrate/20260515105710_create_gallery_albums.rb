class CreateGalleryAlbums < ActiveRecord::Migration[8.0]
  def change
    create_table :gallery_albums do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 0
      t.boolean :visible, default: true

      t.timestamps
    end
  end
end
