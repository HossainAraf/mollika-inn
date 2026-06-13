#!/usr/bin/env bash
set -o errexit

echo "Installing dependencies..."
bundle install --without development:test --deployment --jobs=4 --retry=3

echo "Precompiling assets..."
bundle exec rails assets:precompile --trace
bundle exec rails assets:clean

echo "Skipping database setup on build (will run at startup)"
# Don't run migrations here - they'll run in the pre-deploy phase

echo "Build completed!"