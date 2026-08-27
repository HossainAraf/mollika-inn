# AGENTS.md

## Project context

Mollika Inn is a Rails 8 hotel management app for a boutique inn. The codebase has a strong public-facing guest experience and a separate admin dashboard.

Primary references:
- [docs/README.md](docs/README.md)
- [docs/SETUP.md](docs/SETUP.md)
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/AUTH.md](docs/AUTH.md)
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- [README.md](README.md)

## Working conventions

- Prefer idiomatic Rails patterns over framework- or app-specific shortcuts.
- Keep business logic in models/services and views thin; follow the existing controller structure under `app/controllers`.
- Use the `mollika` PostgreSQL schema for new tables and migrations unless the task explicitly requires otherwise.
- Do not assume a Node.js build pipeline; this app uses Hotwire, Turbo, Stimulus, and Importmap.
- Public pages are mostly guest-facing and should not require admin auth; admin pages live under the `admin` namespace and follow the existing route patterns in [config/routes.rb](config/routes.rb).
- Reuse the established patterns for flash messages, layouts, and helper methods instead of introducing new conventions.

## Typical task flow

1. Read the relevant docs before editing broad behavior.
2. Find the existing controller/model/view pattern closest to the feature you are changing.
3. Make the smallest change that matches the current architecture.
4. Validate with the most targeted Rails command available.

## Commands to prefer

- Start app: `bundle exec rails server -b 0.0.0.0 -p 5000`
- Run tests: `bundle exec rails test`
- Run a focused test: `bundle exec rails test test/models/...` or `bundle exec rails test test/controllers/...`
- Check routes: `bundle exec rails routes`
- Migrate DB: `bundle exec rails db:migrate`
- Open console: `bundle exec rails console`

## Important project-specific notes

- The app intentionally uses a custom PostgreSQL schema and a single admin credential setup via environment variables.
- Rate snapshots are stored on booking records so historic pricing remains stable.
- Admin route flows and public booking flows are separate; do not merge them unless a task explicitly requires it.
- The docs in `docs/` are the source of truth for setup, auth, and day-to-day development workflow. Use them before inventing a new workflow.

## When making changes

- Preserve the app’s existing patterns for admin CRUD, booking logic, and guest-facing pages.
- Prefer minimal, surgical edits. Avoid unrelated refactors.
- If the task touches auth, schema setup, or booking logic, review the matching docs before implementation.
- Keep new code consistent with the project’s Rails 8 + Hotwire stack and existing naming patterns.
