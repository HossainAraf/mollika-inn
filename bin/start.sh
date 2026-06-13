#!/usr/bin/env bash
set -o errexit

echo "Starting application..."
echo "Environment: ${RAILS_ENV:-production}"

# Just run any pending migrations (in case schema changed)
bundle exec rails db:migrate 2>/dev/null || true

echo "Starting Puma..."
exec bundle exec puma -C config/puma.rb