#!/usr/bin/env bash
# Exit immediately if any command exits with a non-zero status
set -o errexit

# 1. Install dependencies
echo "Installing dependencies..."
bundle install

# 2. Precompile assets 
echo "Precompiling assets..."
bundle exec rails assets:precompile
bundle exec rails assets:clean

# 3. Update the database
echo "Running database migrations..."
bundle exec rails db:migrate
