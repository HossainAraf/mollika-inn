class CreateAdminNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_notifications do |t|
      t.references :booking, null: true, foreign_key: { on_delete: :nullify }
      t.string :notification_type, null: false, default: "booking_created"
      t.string :title, null: false
      t.text :body, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :admin_notifications, [ :read_at, :created_at ]
    add_index :admin_notifications, :notification_type
  end
end
