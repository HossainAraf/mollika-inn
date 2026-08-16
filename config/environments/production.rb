require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true # Make this false for free tire performance opt. , But false can cause autoloading issues in background jobs, especially with Solid Queue.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  config.active_storage.service = :local
  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = :debug # Reduce logging for performance (After testing, we'll change it back to :warn.)
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false
  config.cache_store = :memory_store # Use memory store instead of solid_cache for free tier
  config.active_job.queue_adapter = :solid_queue
  config.action_cable.mount_path = "/cable"
  config.action_cable.disable_request_forgery_protection = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :smtp

  config.action_mailer.default_url_options = {
  host: ENV.fetch("APP_HOST", "example.com")
}

config.action_mailer.smtp_settings = {
  address: ENV.fetch("SMTP_ADDRESS"),
  port: ENV.fetch("SMTP_PORT", 587).to_i,
  domain: ENV.fetch("APP_HOST"),
  user_name: ENV.fetch("SMTP_USERNAME"),
  password: ENV.fetch("SMTP_PASSWORD"),
  authentication: :plain,
  enable_starttls_auto: true,
  open_timeout: 30,
  read_timeout: 30
}

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]
  config.assets.compile = false
  config.active_record.query_log_tags_enabled = false # Disable query logging for performance
  # config.active_record.sqlite3_production_warning = false  # REMOVED - doesn't exist in Rails 8
end
