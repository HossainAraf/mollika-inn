class CreateGalleryImages < ActiveRecord::Migration[8.0]
  def change
    create_table :gallery_images do |t|
      t.references :gallery_album, null: false, foreign_key: true
      t.string :caption
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
