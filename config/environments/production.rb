# Cache configuration - just set the store
config.cache_store = :solid_cache_store

# Queue configuration
config.active_job.queue_adapter = :solid_queue

# Action Cable
config.action_cable.mount_path = "/cable"
config.action_cable.disable_request_forgery_protection = true

# Don't add any additional connects_to or database configurations here