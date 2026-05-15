class CreateGuests < ActiveRecord::Migration[8.1]
  def change
    create_table :guests do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false, index: { unique: true }
      t.string :phone
      t.string :nid_or_passport
      t.text :address
      t.string :nationality
      t.string :password_digest
      t.timestamps
    end
  end
end
