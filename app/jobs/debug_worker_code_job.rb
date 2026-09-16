class DebugWorkerCodeJob < ApplicationJob
  queue_as :default

  def perform
    path = Rails.root.join("app/jobs/admin_booking_notification_job.rb")
    source = File.read(path)

    perform_lines = source.lines.select do |line|
      line.match?(/^\s*def perform/)
    end

    Rails.logger.warn(
      "[DEBUG WORKER PERFORM] " \
      "file=#{perform_lines.map(&:strip).inspect} " \
      "loaded=#{AdminBookingNotificationJob.instance_method(:perform).parameters.inspect}"
    )
  end
end