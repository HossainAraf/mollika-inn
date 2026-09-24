# Mollika Inn — Quickstart

This is a concise quickstart to get a development environment running locally.

Prerequisites

- Ruby 3.2
- PostgreSQL
- ImageMagick (for Active Storage variants)

Local quickstart

```bash
git clone <repo-url>
cd mollika-inn
bundle install

# Set DATABASE_URL or edit config/database.yml
export DATABASE_URL=postgresql://user:password@localhost/mollika_dev

bundle exec rails db:create db:migrate db:seed
bundle exec rails server -b 0.0.0.0 -p 5000
```

Admin login (demo)

- Email: `admin@mollikainn.com`
- Password: `mollika2025`

Notes

- The app uses a custom PostgreSQL schema `mollika` — migrations create tables in that schema.
- No Node.js build pipeline: assets served via Propshaft + Importmap.
