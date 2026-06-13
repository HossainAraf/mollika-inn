#!/usr/bin/env bash
set -o errexit

echo "Starting application..."

# Wait for database to be ready
if [ -n "$DATABASE_URL" ]; then
  echo "Checking database connection..."
  bundle exec rails db:version || bundle exec rails db:create db:migrate
fi

echo "Starting Puma..."
bundle exec puma -C config/puma.rb