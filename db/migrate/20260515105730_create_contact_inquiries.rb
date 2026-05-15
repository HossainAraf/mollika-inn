class CreateContactInquiries < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_inquiries do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :subject
      t.text :message
      t.string :status, default: "new"
      t.datetime :replied_at

      t.timestamps
    end
  end
end
