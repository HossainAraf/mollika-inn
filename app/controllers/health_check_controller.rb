class HealthCheckController < ActionController::Base
  def show
    status = :ok
    checks = { web: true }

    if ENV["SOLID_QUEUE_IN_PUMA"].present?
      checks[:solid_queue] = solid_queue_ok?
      status = :service_unavailable unless checks[:solid_queue]
    end

    render json: { status: status == :ok ? "ok" : "unavailable", checks: checks }, status: status
  end

  private

  def solid_queue_ok?
    return false unless defined?(SolidQueue::Process)

    SolidQueue::Process.where("last_heartbeat_at > ?", 1.minute.ago).exists?
  rescue StandardError
    false
  end
end
