---
name: Mollika Inn Rails setup
description: Critical config fixes needed to run Rails 8.1 on Replit with PostgreSQL mollika schema
---

## Key environment facts

- Ruby 3.2.2 installed via `ruby-3.2` module. Gems bundled to `./vendor/bundle` via bundler 4.0.8.
- Workflow command: `bundle exec rails server -b 0.0.0.0 -p 5000` (no bash_profile needed)
- PostgreSQL uses a `mollika` schema. `config/database.yml` uses `DATABASE_URL` env var (Replit-provided). `schema_search_path: "mollika, public"` in all environments.
- All 17 migrations are up. `db:seed` populates full demo data (13 rooms, 9 bookings, 26 menu items, etc).

## Required system dependencies

- `libyaml` — required for the `psych` gem (YAML parsing). Without it, bundle install fails.
- `postgresql_16` — provides PostgreSQL client libraries. `pg_config` is in the older `postgresql-16.5-dev` package at `/nix/store/207n898zbi7mb5scjaf532v78c3rll9f-postgresql-16.5-dev/bin/pg_config`.
- Bundle config: `bundle config build.pg --with-pg-config=/nix/store/207n898zbi7mb5scjaf532v78c3rll9f-postgresql-16.5-dev/bin/pg_config`

## Required config changes for Replit preview

1. **`config/database.yml`** — replaced encrypted credentials with `url: <%= ENV["DATABASE_URL"] %>` in all environments.
2. **`config.hosts.clear`** in `config/environments/development.rb` — already present (fixes blocked host errors).

## Auth

- No User model. Session-based: `session[:admin_authenticated] = true`.
- Admin email/password via `ADMIN_EMAIL` / `ADMIN_PASSWORD` env vars (set in shared environment).
- Demo credentials: `admin@mollikainn.com` / `mollika2025`.
- `SessionsController#valid_admin_credentials?` falls back to ENV vars if credentials file missing.

## GalleryImage

- `validates :image, presence: true` — seeds must use `save(validate: false)` for placeholder images.
- Gallery views use external Unsplash URLs directly (not ActiveStorage) for demo images.

**Why:** These issues are non-obvious Rails 8 + Replit-specific quirks that took multiple rounds to fix.
