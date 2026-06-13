require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Solid gems
  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :solid_queue

  # Public file server
  config.public_file_server.enabled = true

  # Assets
  config.assets.compile = true
end
