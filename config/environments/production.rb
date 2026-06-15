require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false # Made this false for free tire performance opt.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  config.active_storage.service = :local
  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "warn") # Reduce logging for performance
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false
  config.cache_store = :memory_store # Use memory store instead of solid_cache for free tier
  config.active_job.queue_adapter = :async # Use async instead of solid_queue for free tier
  config.action_cable.mount_path = "/cable"
  config.action_cable.disable_request_forgery_protection = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: ENV.fetch("RENDER_EXTERNAL_URL", "example.com") }
  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]
  config.assets.compile = false
  config.active_record.query_log_tags_enabled = false # Disable query logging for performance
  # config.active_record.sqlite3_production_warning = false  # REMOVED - doesn't exist in Rails 8
end
