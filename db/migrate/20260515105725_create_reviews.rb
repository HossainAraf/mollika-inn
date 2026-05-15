class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :guest, null: false, foreign_key: true
      t.integer :rating, null: false
      t.string :title
      t.text :body
      t.integer :cleanliness_rating
      t.integer :service_rating
      t.integer :value_rating
      t.boolean :approved, default: false

      t.timestamps
    end
  end
end
