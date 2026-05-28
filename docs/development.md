# Development

Install dependencies:

```bash
bundle install
```

Run the default local verification:

```bash
bundle exec rake
```

The default task runs the test suite and RuboCop.

Useful focused commands:

```bash
bundle exec rake test
bundle exec rubocop
bundle exec ruby test/dummy/bin/rails runner 'puts Mempalace::Engine.engine_name'
```

## PostgreSQL and pgvector

The default test suite uses SQLite and verifies graceful fallback behavior. PostgreSQL/pgvector coverage is available when a database URL is provided:

```bash
MEMPALACE_POSTGRES_URL=postgres://user:pass@localhost/mempalace_test bundle exec rake test
```

If PostgreSQL is reachable but the `vector` extension is unavailable, the pgvector-specific assertion is skipped.

## CI

GitHub Actions runs:

- `bundle exec rake`
- `bundle exec rubocop`

The matrix currently covers Ruby 3.2 and 3.3.
