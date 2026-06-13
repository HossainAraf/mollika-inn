# Replace the default in-process memory cache store with a durable alternative.
config.cache_store = :solid_cache_store

# Replace the default in-process and non-durable queuing backend for Active Job.
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }

# Configure Solid Cable for Action Cable
config.action_cable.mount_path = "/cable"
config.action_cable.disable_request_forgery_protection = true
