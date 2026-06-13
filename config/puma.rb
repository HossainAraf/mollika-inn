# config/puma.rb
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count)
threads min_threads_count, max_threads_count

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RACK_ENV", "production")

pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Single mode for free tier
workers 0
preload_app! false

# Increase timeouts for free tier
worker_timeout 120
worker_shutdown_timeout 60

# Bind to all interfaces
bind "tcp://0.0.0.0:#{ENV.fetch('PORT', 3000)}"

plugin :tmp_restart
