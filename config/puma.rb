# config/puma.rb
# !/usr/bin/env puma

# Single mode only
workers 0
threads 1, 3

# Port and environment
port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "production")

# Don't preload
preload_app! false

# Output to stdout
stdout_redirect nil, nil, true

# Quiet down output
quiet true if ENV["RACK_ENV"] == "production"

# Timeouts
worker_timeout 30
worker_shutdown_timeout 30
