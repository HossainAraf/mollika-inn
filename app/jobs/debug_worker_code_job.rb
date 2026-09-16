class DebugWorkerCodeJob < ApplicationJob
  queue_as :default

  def perform
    job = AdminBookingNotificationJob

    Rails.logger.warn(
      "[DEBUG WORKER CODE] " \
      "root=#{Rails.root} " \
      "source=#{job.instance_method(:perform).source_location.inspect} " \
      "parameters=#{job.instance_method(:perform).parameters.inspect}"
    )
  end
end