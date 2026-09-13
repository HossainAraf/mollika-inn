class Admin::NotificationsController < Admin::BaseController
  def index
    @notifications = AdminNotification.recent.includes(:booking).limit(100)
    @unread_count = AdminNotification.unread.count
  end

  def mark_all_read
    AdminNotification.unread.update_all(read_at: Time.current, updated_at: Time.current)
    AdminNotification.broadcast_widget!

    redirect_to admin_notifications_path, notice: "All notifications marked as read."
  end

  def mark_read
    notification = AdminNotification.find_by(id: params[:id])
    if notification && !notification.read?
      notification.mark_as_read!
    end

    redirect_to admin_notifications_path, notice: "Notification marked as read."
  end
end
