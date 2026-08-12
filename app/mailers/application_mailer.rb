class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("DEFAULT_FROM_EMAIL", "a.hossain21st@gmail.com")
  layout "mailer"
end