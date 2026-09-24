# Contributing to Mollika Inn

Thank you for contributing! This project follows a simple workflow:

- Fork the repo and create a feature branch
- Write tests for new behavior where applicable
- Keep changes small and focused
- Open a PR with a clear title and description

Developer workflow

```bash
git checkout -b feat/description
# make changes
bundle exec rails test      # run tests
git add -A
git commit -m "feat: ..."
git push origin feat/description
# Open PR
```

Testing

- Unit tests: `bundle exec rails test test/models` etc.
- Integration: `bundle exec rails test test/integration`

Style

- Follow existing Rails conventions used across the repo
- Use clear service objects for complex business logic
- Keep views thin; prefer partials and helpers

Docs

- Update `docs/` when changing behavior or adding features
- Add small HOWTOs under `docs/` for anything non-obvious
