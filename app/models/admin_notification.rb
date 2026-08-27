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
    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_notifications",
      target: "admin-notification-widget",
      partial: "admin/notifications/widget",
      locals: {
        notifications: recent.limit(5).includes(:booking),
        unread_count: unread.count
      }
    )
  end

  private

  def broadcast_widget
    self.class.broadcast_widget!
  end
end
