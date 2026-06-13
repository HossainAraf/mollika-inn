#!/usr/bin/env bash
set -o errexit

echo "Starting application..."
echo "Ruby version: $(ruby --version)"
echo "Rails version: $(bundle exec rails --version)"
echo "Environment: ${RAILS_ENV:-production}"
echo "Port: ${PORT:-3000}"

# Database setup
if [ -n "$DATABASE_URL" ]; then
  echo "Setting up databases..."
  
  # Primary database
  bundle exec rails db:prepare
  
  # Solid Queue database migrations
  echo "Running Solid Queue migrations..."
  bundle exec rails solid_queue:install:migrations
  bundle exec rails db:migrate
  
  # Solid Cable database migrations
  echo "Running Solid Cable migrations..."
  bundle exec rails solid_cable:install:migrations
  bundle exec rails db:migrate
  
  # Solid Cache doesn't need separate migrations
fi

echo "Starting Puma..."
exec bundle exec puma -C config/puma.rb