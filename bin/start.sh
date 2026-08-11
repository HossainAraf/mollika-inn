#!/usr/bin/env bash
set -o errexit

echo "Starting application..."
echo "Environment: ${RAILS_ENV:-production}"

# Only prepare the database if the database URL is available
if [ -n "$DATABASE_URL" ]; then
  echo "Preparing database..."
  bundle exec rails db:prepare
fi

echo "Starting Puma..."
exec bundle exec puma -C config/puma.rb