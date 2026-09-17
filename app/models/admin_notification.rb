class AdminNotification < ApplicationRecord
  belongs_to :booking, optional: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  validates :title, :body, :notification_type, presence: true

  after_update_commit :broadcast_widget, if: :saved_change_to_read_at?

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current)
  end

  def self.broadcast_widget!
    notifications = recent.limit(5).includes(:booking)
    unread_count = unread.count

    Turbo::StreamsChannel.broadcast_update_to(
      "admin_notifications",
      target: "admin-notification-count",
      partial: "admin/notifications/count",
      locals: { unread_count: unread_count }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      "admin_notifications",
      target: "admin-notification-list",
      partial: "admin/notifications/list",
      locals: { notifications: notifications }
    )
  end

  private

  def broadcast_widget
    self.class.broadcast_widget!
  end
end
