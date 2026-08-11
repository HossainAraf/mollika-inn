class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("DEFAULT_FROM_EMAIL", "no-reply@#{ENV.fetch("RENDER_EXTERNAL_URL", "example.com")}")
  layout "mailer"
end
