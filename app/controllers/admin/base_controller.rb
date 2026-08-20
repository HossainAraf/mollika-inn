class Admin::BaseController < ApplicationController
  before_action :require_admin!
  before_action :set_admin_notifications

  layout "admin"

  private

  def require_admin!
    unless authenticated?
      redirect_to new_session_path, alert: "Please sign in to access the admin panel."
    end
  end

  def set_admin_notifications
    @admin_notifications = AdminNotification.recent.includes(:booking).limit(5)
    @admin_unread_notifications_count = AdminNotification.unread.count
  end
end
