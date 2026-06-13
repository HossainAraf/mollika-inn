#!/usr/bin/env bash
set -o errexit

echo "Starting application..."
echo "Ruby version: $(ruby --version)"
echo "Rails version: $(bundle exec rails --version)"
echo "Environment: ${RAILS_ENV:-production}"
echo "Port: ${PORT:-3000}"

# Check database connection
if [ -n "$DATABASE_URL" ]; then
  echo "Checking database connection..."
  bundle exec rails db:version || {
    echo "Database not ready, creating..."
    bundle exec rails db:create db:migrate
  }
else
  echo "No DATABASE_URL set, skipping database check"
fi

echo "Starting Puma..."
exec bundle exec puma -C config/puma.rb