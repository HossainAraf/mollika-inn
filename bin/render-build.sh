#!/usr/bin/env bash
set -o errexit

echo "Installing dependencies..."
bundle install

echo "Precompiling assets..."
bundle exec rails assets:precompile

echo "Running migrations during build..."
bundle exec rails db:create 2>/dev/null || true
bundle exec rails db:migrate

echo "Build completed!"