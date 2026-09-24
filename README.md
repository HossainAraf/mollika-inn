# Mollika Inn — Repository Overview

This repository contains the Mollika Inn Rails 8 application. Full documentation
and developer guides live under the `docs/` directory. Start with the docs
index below.

- Documentation: [docs/README.md](docs/README.md)
- Quick start and local commands: [docs/QUICKSTART.md](docs/QUICKSTART.md)
- Developer guide: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- Setup instructions: [docs/SETUP.md](docs/SETUP.md)

If you are contributing, please read the contributing guidelines:
[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)

If you maintain deployments, check the changelog for releases and notes:
[docs/CHANGELOG.md](docs/CHANGELOG.md)

Common commands

```bash
# Install dependencies
bundle install

# Create and migrate DB
bundle exec rails db:create db:migrate

# Seed demo data
bundle exec rails db:seed

# Run the server
bundle exec rails server -b 0.0.0.0 -p 5000
```
