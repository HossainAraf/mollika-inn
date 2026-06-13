#!/usr/bin/env bash
set -o errexit

echo "Starting application..."
echo "Environment: ${RAILS_ENV:-production}"

# Only run migrations if needed
if [ -n "$DATABASE_URL" ]; then
  echo "Running migrations..."
  bundle exec rails db:migrate 2>/dev/null || true
fi

echo "Starting Puma..."
exec bundle exec puma -C config/puma.rb