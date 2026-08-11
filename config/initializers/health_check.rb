# config/initializers/health_check.rb
if ENV["RENDER"] == "true"
  Rails.application.routes.append do
    get "/health", to: "health_check#show"
  end
end
