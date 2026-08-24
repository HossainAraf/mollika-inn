require "net/http"
require "uri"
require "json"

class BrevoMailer
  API_URL = URI("https://api.brevo.com/v3/smtp/email")

  def self.send_email(to:, subject:, html_content:, sender_name: "Mollika Inn")
    api_key = ENV.fetch("BREVO_API_KEY")
    from_email = ENV.fetch("DEFAULT_FROM_EMAIL")

    payload = {
      sender: {
        name: sender_name,
        email: from_email
      },
      to: [
        {
          email: to
        }
      ],
      subject: subject,
      htmlContent: html_content
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
