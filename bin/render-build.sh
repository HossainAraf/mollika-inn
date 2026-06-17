#!/usr/bin/env bash
set -o errexit

echo "Installing dependencies..."
bundle install

echo "Precompiling assets..."
bundle exec rails assets:precompile

echo "Running migrations during build with silencing errors and redirecting all error output to /dev/null..."
bundle exec rails db:migrate 2>/dev/null || true

echo "Build completed!"