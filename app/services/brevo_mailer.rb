require "net/http"
require "uri"
require "json"

class BrevoMailer
  API_URL = URI("https://api.brevo.com/v3/smtp/email")

  def self.send_test_email(to:)
    api_key = ENV.fetch("BREVO_API_KEY")
    from_email = ENV.fetch("DEFAULT_FROM_EMAIL")

    payload = {
      sender: {
        name: "Mollika Inn",
        email: from_email
      },
      to: [
        {
          email: to
        }
      ],
      subject: "Mollika Inn - Brevo API Test",
      htmlContent: <<~HTML
        <h1>Brevo API Test</h1>
        <p>This is a test email from the Mollika Inn Rails application.</p>
        <p>If you received this email, HTTPS communication between Render and Brevo is working.</p>
      HTML
    }

    http = Net::HTTP.new(API_URL.host, API_URL.port)
    http.use_ssl = true
    http.open_timeout = 15
    http.read_timeout = 30

    request = Net::HTTP::Post.new(API_URL.request_uri)

    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request["api-key"] = api_key
    request.body = JSON.generate(payload)

    response = http.request(request)

    Rails.logger.info(
      "[BrevoMailer] Response: #{response.code} #{response.body}"
    )

    unless response.is_a?(Net::HTTPSuccess)
      raise "Brevo API error: HTTP #{response.code} - #{response.body}"
    end

    response
  end
end