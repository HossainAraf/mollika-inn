# config/puma.rb - Optimized for Render.com free tier
threads_count = ENV.fetch("RAILS_MAX_THREADS", 1)
threads threads_count, threads_count

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RACK_ENV", "production")

solid_queue_enabled = ENV["SOLID_QUEUE_IN_PUMA"].to_s != ""
if solid_queue_enabled
  plugin :solid_queue
end

workers 0
preload_app! false

# Timeout settings for free tier
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"
worker_timeout 15 # Free tier needs shorter timeout

# Memory optimization
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
