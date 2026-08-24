class HealthController < ApplicationController
  def brevo_test
    expected_token = ENV.fetch("BREVO_TEST_TOKEN")

    unless ActiveSupport::SecurityUtils.secure_compare(
      token.to_s,
      expected_token
    )
      render plain: "Unauthorized", status: :unauthorized
      return
    end

    BrevoMailer.send_test_email(
      to: "a.hossain21st@gmail.com"
    )

    render plain: "Brevo test email request accepted"
  rescue => e
    Rails.logger.error("[BrevoTest] #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    render plain: "Brevo test failed: #{e.class} - #{e.message}", status: :internal_server_error
  end

  private

  def token
    params[:token]
  end
end