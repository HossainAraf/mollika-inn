# config/puma.rb
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count)
threads min_threads_count, max_threads_count

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RACK_ENV", "development")

pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Single worker mode for free tier
workers 0
preload_app! false

plugin :tmp_restart
