# config/puma.rb
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count)
threads min_threads_count, max_threads_count

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RACK_ENV", "development")

pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# For free plan on Render - disable workers and preloading
if ENV.fetch("RENDER", nil) == "true"
  workers 0  # Disable workers on Render free tier
  preload_app! false
else
  workers ENV.fetch("WEB_CONCURRENCY", 2)
  preload_app!
end

# Only run on_worker_boot if we have workers
if workers > 0
  on_worker_boot do
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  end
end

plugin :tmp_restart