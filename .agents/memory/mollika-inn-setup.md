---
name: Mollika Inn Rails setup
description: Critical config fixes needed to run Rails 8.1 on Replit with PostgreSQL mollika schema
---

## Key environment facts

- Ruby at `/nix/store/2bpi29al123830q6p1z86rrf5j25pxdw-ruby-3.2.2/bin/`; gems at `/home/runner/workspace/.local/share/gem/ruby/3.2.0/bin/`. Always `source /home/runner/.bash_profile` before running rails/bundle commands.
- Workflow command: `source /home/runner/.bash_profile && bundle exec rails server -b 0.0.0.0 -p 5000`
- PostgreSQL uses a `mollika` schema. `config/database.yml` must have `schema_search_path: "mollika,public"` in the default block.
- `db:schema:load` will fail if run twice (schema already exists). Just run `db:seed` directly on an existing DB.

## Required config changes for Replit preview

1. **Remove `allow_browser versions: :modern`** from `ApplicationController` — Rails 8 blocks Replit's proxy browser agent with a 406.
2. **Add `config.hosts.clear`** to `config/environments/development.rb` — fixes "Blocked hosts: *.replit.dev" error.

## Auth

- No User model. Session-based: `session[:admin_authenticated] = true`.
- Admin email/password via `ADMIN_EMAIL` / `ADMIN_PASSWORD` env vars (set in shared environment).
- Demo credentials: `admin@mollikainn.com` / `mollika2025`.

## GalleryImage

- `validates :image, presence: true` — seeds must use `save(validate: false)` for placeholder images.
- Gallery views use external Unsplash URLs directly (not ActiveStorage) for demo images.

**Why:** These issues are non-obvious Rails 8 + Replit-specific quirks that took multiple rounds to fix.
