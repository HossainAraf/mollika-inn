# Mollika Inn — Setup Guide

## Prerequisites

- Ruby 3.2 (installed automatically in Replit via the `ruby-3.2` module)
- PostgreSQL (provided by Replit's built-in database)
- Bundler 4.x (included with the Ruby module)

## Replit Setup (Recommended)

The project is configured to run on Replit with zero manual configuration.

### 1. Environment Variables

The following are pre-configured in the Replit shared environment:

| Variable         | Value                    | Purpose                        |
|------------------|--------------------------|--------------------------------|
| `ADMIN_EMAIL`    | `admin@mollikainn.com`   | Admin login email              |
| `ADMIN_PASSWORD` | `mollika2025`            | Admin login password           |
| `DATABASE_URL`   | *(auto-provisioned)*     | Replit PostgreSQL connection   |

> To change admin credentials, update `ADMIN_EMAIL` and `ADMIN_PASSWORD` in the **Secrets** tab. No code changes required.

### 2. First-Time Database Setup

Run these once after cloning or on a fresh environment:

```bash
bundle install
bundle exec rails db:migrate
bundle exec rails db:seed       # loads demo data (rooms, bookings, menu, etc.)
```

### 3. Start the Server

```bash
bundle exec rails server -b 0.0.0.0 -p 5000
```

The app is available at port 5000 (Replit proxies this to the preview pane).

---

## Local Development Setup

### System Dependencies

Install these via your OS package manager before `bundle install`:

- **PostgreSQL** (client libraries + `pg_config` binary)
- **libyaml** (required for the `psych` gem)
- **ImageMagick** (required for `image_processing`)

On macOS (Homebrew):
```bash
brew install postgresql libyaml imagemagick
```

On Ubuntu/Debian:
```bash
sudo apt install postgresql libpq-dev libyaml-dev imagemagick
```

### Installation

```bash
git clone <repo-url>
cd mollika-inn

bundle install

# Configure database credentials
# Either set DATABASE_URL env var, or edit config/database.yml
export DATABASE_URL=postgresql://user:password@localhost/mollika_dev

bundle exec rails db:migrate
bundle exec rails db:seed
bundle exec rails server
```

### pg gem (native extension)

If `bundle install` fails on the `pg` gem, specify `pg_config` explicitly:

```bash
bundle config build.pg --with-pg-config=$(which pg_config)
bundle install
```

---

## Gemfile Key Dependencies

| Gem              | Purpose                                      |
|------------------|----------------------------------------------|
| `rails ~> 8.1`   | Web framework                                |
| `pg ~> 1.6`      | PostgreSQL adapter                           |
| `puma`           | Web server                                   |
| `propshaft`      | Asset pipeline (replaces Sprockets)          |
| `importmap-rails`| JS module map (no bundler needed)            |
| `turbo-rails`    | Hotwire Turbo (SPA-like navigation)          |
| `stimulus-rails` | Hotwire Stimulus (JS controllers)            |
| `solid_cache`    | Database-backed Rails cache                  |
| `solid_queue`    | Database-backed background jobs              |
| `solid_cable`    | Database-backed Action Cable                 |
| `image_processing`| Active Storage image variants               |
| `bootsnap`       | Boot time caching                            |

---

## Database

- **Adapter:** PostgreSQL
- **Custom schema:** All tables live in the `mollika` schema (not `public`)
- **Schema search path:** `mollika, public` — set in `config/database.yml`
- **Connection:** Always via `DATABASE_URL` environment variable

### Migrations

```bash
bundle exec rails db:migrate           # run pending migrations
bundle exec rails db:migrate:status    # check migration state
bundle exec rails db:rollback          # rollback last migration
bundle exec rails db:schema:load       # load schema from scratch (new DB only)
```

### Resetting Demo Data

```bash
bundle exec rails db:seed              # re-seeds all demo data (clears existing)
```
