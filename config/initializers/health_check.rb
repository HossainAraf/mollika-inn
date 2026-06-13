# config/initializers/health_check.rb
if ENV["RENDER"] == "true"
  Rails.application.routes.append do
    get "/health" => proc { [200, {}, ["OK"]] }
  end
end