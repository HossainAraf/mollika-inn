class DebugWorkerCodeJob < ApplicationJob
  queue_as :default

  def perform
    path = Rails.root.join("app/jobs/admin_booking_notification_job.rb")

    Rails.logger.warn(
      "[DEBUG WORKER CODE] " \
      "root=#{Rails.root} " \
      "source=#{AdminBookingNotificationJob.instance_method(:perform).source_location.inspect} " \
      "parameters=#{AdminBookingNotificationJob.instance_method(:perform).parameters.inspect}"
    )

    Rails.logger.warn(
      "[DEBUG WORKER FILE] " \
      "#{File.read(path).lines.first(10).join}"
    )
  end
end