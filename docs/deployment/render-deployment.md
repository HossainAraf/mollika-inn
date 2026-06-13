# Deployment Documentation: Mollika Inn Hotel Booking System

## 🎉 Current Deployment Status

**Live URL:** https://hotel-booking-agfq.onrender.com 
**Platform:** Render (Free Tier)  
**Ruby Version:** 3.4.4  
**Rails Version:** 8.1.3  
**Database:** PostgreSQL 18 (Render Managed)  
**Web Server:** Puma 8.0.1 (Single Mode)

---

## 📋 Table of Contents

1. [Deployment Architecture](#deployment-architecture)
2. [Current Configuration](#current-configuration)
3. [Environment Variables](#environment-variables)
4. [Database Setup](#database-setup)
5. [Troubleshooting Common Issues](#troubleshooting-common-issues)
6. [Migration to Paid Server](#migration-to-paid-server)
7. [Performance Optimization](#performance-optimization)
8. [Monitoring & Maintenance](#monitoring--maintenance)
9. [Backup & Recovery](#backup--recovery)
10. [Future Implementation Roadmap](#future-implementation-roadmap)

---

## 🏗️ Deployment Architecture

### Current Setup (Free Tier)
```
┌─────────────────────────────────────────┐
│         Render Platform                  │
├─────────────────────────────────────────┤
│  Web Service (hotel-booking)            │
│  ├── RAM: 512 MB                         │
│  ├── CPU: Shared                         │
│  ├── Workers: 0 (Single Mode)           │
│  └── Threads: 3                          │
├─────────────────────────────────────────┤
│  PostgreSQL Database (utd_bd)           │
│  ├── RAM: 256 MB                         │
│  ├── Disk: 1 GB                          │
│  └── Version: PostgreSQL 18              │
└─────────────────────────────────────────┘
```

## Key Files Structure
```text
mollika-inn/
├── .ruby-version (3.4.4)
├── Gemfile & Gemfile.lock
├── config/
│   ├── database.yml
│   ├── puma.rb
│   ├── cable.yml
│   ├── queue.yml
│   ├── cache.yml
│   └── environments/
│       └── production.rb
├── bin/
│   ├── render-build.sh
│   └── start.sh
├── db/
│   ├── migrate/
│   ├── schema.rb
│   └── seeds.rb
└── render.yaml
```

## ⚙️ Current Configuration

### 1. Database Configuration (config/database.yml)

```yaml
production:
  primary:
    adapter: postgresql
    url: <%= ENV["DATABASE_URL"] %>
    schema_search_path: "mollika,public"
  
  queue:
    url: <%= ENV["DATABASE_URL"] %>
    schema_search_path: "mollika,public"
  
  cable:
    url: <%= ENV["DATABASE_URL"] %>
    schema_search_path: "mollika,public"
```

### 2. Puma Configuration (config/puma.rb)

```ruby
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RACK_ENV", "production")

workers 0  # Single mode for free tier
preload_app! false
```


3. Build Script (bin/render-build.sh)
```bash
#!/usr/bin/env bash
bundle install
bundle exec rails assets:precompile
bundle exec rails db:prepare
```
4. Start Script (bin/start.sh)
```bash
#!/usr/bin/env bash
bundle exec rails db:migrate 2>/dev/null || true
exec bundle exec puma -C config/puma.rb
```
###  🔐 Environment Variables
Required Variables (Set in Render Dashboard)

Variable	    Value	    Description
RAILS_MASTER_KEY		      Rails credentials key
DATABASE_URL	postgresql://user:pass@host:5432/<databaseName>	PostgreSQL connection string
RAILS_ENV	production	Rails environment
RACK_ENV	production	Rack environment
PORT	10000	Application port
RAILS_LOG_TO_STDOUT	true	Log to console
RAILS_MAX_THREADS	3	Puma threads
RENDER	true	Render environment flag
Optional Variables (For Paid Plan)
Variable	Default	When to Use
WEB_CONCURRENCY	2	When upgrading to paid plan
RAILS_MIN_THREADS	3	Performance tuning
DB_POOL	5	Database connection pool
SOLID_QUEUE_POLLING_INTERVAL	0.1	Background jobs

### 🗄️ Database Schema
PostgreSQL Schemas
```sql

-- Current schemas
mollika   -- Main application tables
public    -- Default schema
salehobe  -- Legacy/Other
utech     -- Legacy/Other
```
Key Tables (in mollika schema)

    room_types - Room categories and pricing

    rooms - Individual room instances

    bookings - Reservation records

    guests - Customer information

    rates - Dynamic pricing rules

    facilities - Hotel amenities

    reviews - Guest feedback

    menu_items - Restaurant menu

    dining_reservations - Restaurant bookings

### 🔧 Troubleshooting Common Issues
#### Issue 1: Port Already in Use

Error: Address already in use - bind(2) for "0.0.0.0" port 10000

Solution:
```bash

# Kill existing Puma process
pkill -f puma

# Remove pid file
rm -f tmp/pids/server.pid

# Restart service via Render dashboard
```
#### Issue 2: Schema Search Path

Error: relation "room_types" does not exist

Solution:
```sql

-- Set default schema search path
ALTER DATABASE utd_bd SET search_path TO mollika, public;

-- Verify
SHOW search_path;
```

#### Issue 3: Missing Tables During Migration

Error: PG::DuplicateSchema: schema "mollika" already exists

Solution:
```ruby

# Comment out in db/schema.rb
# create_schema "mollika"
```
#### Issue 4: Memory Exhaustion (Free Tier)

Symptoms: Slow response, 502 errors, SIGTERM

Solutions:

    Reduce threads to 2

    Disable eager loading

    Use memory store instead of solid_cache

    Remove unnecessary gems

### 🚀 Migration to Paid Server
Recommended Plan: Render Starter ($7/month)

#### Why Upgrade:

    512 MB RAM → 512 MB (same but better CPU allocation)

    No timeout restrictions

    Better performance

    24/7 support

#### Migration Steps
1. Update render.yaml
```yaml

services:
  - type: web
    name: hotel-booking
    runtime: ruby
    plan: starter  # Change from 'free' to 'starter'
    envVars:
      - key: WEB_CONCURRENCY
        value: "2"
      - key: RAILS_MAX_THREADS
        value: "5"
```
2. Update config/puma.rb for Paid Plan
```ruby

# config/puma.rb
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count)
threads min_threads_count, max_threads_count

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RACK_ENV", "production")

# Enable workers for paid plan
workers ENV.fetch("WEB_CONCURRENCY", 2)
preload_app!

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

plugin :tmp_restart
```
3. Enable Solid Gems (Redis Alternative)
```ruby

# Gemfile - Uncomment for paid plan
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# config/environments/production.rb
config.cache_store = :solid_cache_store
config.active_job.queue_adapter = :solid_queue
```
4. Database Connection Pool Tuning
```yaml

# config/database.yml
production:
  primary:
    pool: <%= ENV.fetch("DB_POOL") { 10 } %>
```
##### Migration Checklist

    Upgrade Render plan (free → starter)

    Update environment variables

    Test with staging environment

    Monitor memory usage for 24 hours

    Enable health checks

    Set up auto-scaling (if needed)

#### ⚡ Performance Optimization
For Free Tier (Current)

Do:

    Use single worker mode

    Disable eager loading

    Minimize asset compilation

    Use memory_store for cache

    Use async for job queue

Don't:

    Use Solid gems (cache, queue, cable)

    Enable multiple workers

    Preload application

    Use heavy background jobs

For Paid Plan (Future)

Optimization Settings:
```ruby

# config/environments/production.rb
config.eager_load = true
config.assets.compile = false
config.cache_store = :solid_cache_store
config.active_job.queue_adapter = :solid_queue

# Performance
config.action_controller.perform_caching = true
config.public_file_server.headers = {
  "cache-control" => "public, max-age=#{1.year.to_i}"
}
```
Database Indexing:
```sql

-- Add missing indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS 
  idx_bookings_check_dates ON bookings(check_in_date, check_out_date);
  
CREATE INDEX CONCURRENTLY IF NOT EXISTS 
  idx_room_types_slug ON room_types(slug);
```
### 📊 Monitoring & Maintenance
Health Check Endpoint

Add to config/routes.rb:
```ruby

get "health" => proc { 
  [200, {"Content-Type" => "text/plain"}, ["OK"]] 
}
```
Log Monitoring Commands
```bash

# View recent logs
render logs --service hotel-booking --tail
```
# Check database connections
```
bundle exec rails dbconsole
> SELECT count(*) FROM pg_stat_activity;

# Monitor memory usage
free -h
```
Daily Maintenance Tasks
```bash

# 1. Backup database
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d).sql

# 2. Clean old sessions
bundle exec rails db:session:trim

# 3. Rotate logs
logrotate /etc/logrotate.conf

# 4. Check for failed jobs (when using Solid Queue)
bundle exec rails runner "SolidQueue::FailedJob.count"
```
# 💾 Backup & Recovery
## Automated Backup Script

Create bin/backup.sh:
```bash

#!/usr/bin/env bash
BACKUP_DIR="/opt/render/backups"
mkdir -p $BACKUP_DIR

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/utd_bd_$TIMESTAMP.sql"

pg_dump $DATABASE_URL > $BACKUP_FILE
gzip $BACKUP_FILE

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup created: $BACKUP_FILE.gz"
```
## Recovery Procedure
```bash

# Download latest backup
gzip -d utd_bd_20260101_120000.sql.gz

# Restore to database
psql $DATABASE_URL < utd_bd_20260101_120000.sql

# Run migrations after restore
bundle exec rails db:migrate
```
# 🗺️ Future Implementation Roadmap
Phase 1: Stabilize Free Tier (Current)

    ✅ Basic deployment working

    ✅ Database configured with schema search path

    ✅ Asset pipeline functional

    🔄 Monitor stability for 30 days

Phase 2: Upgrade to Paid Plan (Month 1-2)

Estimated Cost: $7-15/month

    Upgrade Render plan to Starter

    Enable Puma workers (2-4)

    Implement Solid Cache

    Configure Solid Queue for background jobs

    Add Redis for sessions (optional)

Phase 3: Performance Optimization (Month 2-3)

    CDN integration (Cloudflare free tier)

    Database query optimization

    Implement fragment caching

    Add pagination for large queries

    Set up database read replicas

Phase 4: Scalability (Month 3-6)

Estimated Cost: $50-100/month

    Multiple web services (horizontal scaling)

    Load balancer configuration

    Separate background job service

    Dedicated asset server

    Auto-scaling rules

Phase 5: Enterprise Features (6+ months)

    Full-text search (PostgreSQL or Elasticsearch)

    Real-time notifications (Action Cable)

    Analytics dashboard

    API rate limiting

    Advanced monitoring (New Relic/DataDog)

Alternative Cloud Providers Comparison
Provider	Free Tier	Paid Starting	Best For
Render	512 MB RAM	$7/month	Ease of use, Rails optimized
Heroku	512 MB RAM	$25/month	Eco system, add-ons
Fly.io	256 MB RAM	$1.94/month	Global deployment
Railway	512 MB RAM	$5/month	Simplicity
AWS	750 hrs/month	$5/month	Flexibility, control
📝 Recommended Environment Variables for Paid Plan
yaml

# render.yaml for paid plan
services:
  - type: web
    name: hotel-booking
    plan: starter
    envVars:
      - key: WEB_CONCURRENCY
        value: "2"
      - key: RAILS_MAX_THREADS
        value: "5"
      - key: DB_POOL
        value: "10"
      - key: SOLID_QUEUE_POLLING_INTERVAL
        value: "0.1"
      - key: RACK_TIMEOUT
        value: "30"
      - key: NEW_RELIC_APP_NAME
        sync: false
      - key: NEW_RELIC_LICENSE_KEY
        sync: false

# 🔐 Security Recommendations
Immediate Actions
```yaml

# render.yaml
envVars:
  - key: RAILS_MASTER_KEY
    sync: false  # Never commit to repo
  
  - key: DATABASE_URL
    fromDatabase:
      name: utd_bd
      property: connectionString

  - key: SECRET_KEY_BASE
    generateValue: true

  - key: BASIC_AUTH_USERNAME
    sync: false  # For staging protection
  
  - key: BASIC_AUTH_PASSWORD
    sync: false

SSL Configuration (Auto-enabled on Render)

    All traffic forced to HTTPS

    HSTS enabled after 30 days
```
# 📚 Useful Commands Reference
```bash

# Deploy specific branch
git push origin deploy

# Check deployment status
render logs --service hotel-booking --tail

# Run Rails console on Render
render run --service hotel-booking bundle exec rails console

# Database operations
bundle exec rails db:migrate
bundle exec rails db:rollback
bundle exec rails db:seed

# Asset operations
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails assets:clobber

# Restart service
render restart --service hotel-booking
```
# 🆘 Support & Resources

    Render Documentation: https://render.com/docs

    Rails Deployment Guide: https://guides.rubyonrails.org/deploying.html

    Project Repository: https://github.com/HossainAraf/mollika-inn

    Live Site: https://hotel-booking-agfq.onrender.com

✅ Post-Deployment Checklist

    Application loads without errors

    Database migrations run successfully

    Asset pipeline compiles

    Environment variables configured

    Health check endpoint added

    Backup system configured

    Monitoring alerts set up

    SSL certificate verified

    Custom domain configured (if needed)

    Email sending configured (if needed)

Last Updated: June 13, 2026
Deployed By: Hossain Araf
Status: ✅ Production Ready (Free Tier)
