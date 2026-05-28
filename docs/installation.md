# Installation

Add the gem from GitHub:

```ruby
gem "mempalace-rb", github: "aliumairdev/mempalace-rb"
```

After a RubyGems release, the shorter form will work:

```ruby
gem "mempalace-rb"
```

Install and migrate:

```bash
bundle install
bin/rails generate mempalace:install
bin/rails db:migrate
```

The generator creates:

- `config/initializers/mempalace.rb`
- `db/migrate/*_create_mempalace_tables.rb`

PostgreSQL with pgvector is recommended for production, but the gem can run without pgvector. Without pgvector, semantic search degrades and keyword search remains available.
