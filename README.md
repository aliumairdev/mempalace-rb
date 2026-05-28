# mempalace-rb

Rails-native long-term memory for AI agents and Rails apps.

`mempalace-rb` stores Rails app memory as original verbatim text, then makes it searchable through PostgreSQL full-text search, optional pgvector embeddings, and practical Rails APIs for prompt context. It supports simple apps with one memory space and multitenant apps with account-scoped isolation.

## Why Verbatim Memory

Summaries lose source detail. Mempalace stores drawers as the original text you gave it, then layers indexes, pointers, facts, tunnels, and diary entries around that source of truth.

## Install

```ruby
gem "mempalace-rb"
```

Then run:

```bash
bundle install
bin/rails generate mempalace:install
bin/rails db:migrate
```

The installer creates `config/initializers/mempalace.rb` and copies the database migration.

## Configure

```ruby
Mempalace.configure do |config|
  config.embedding_provider = :null
  config.embedding_model = nil
  config.vector_dimensions = 1536
  config.tenant_mode = :multi
  config.tenant_model = "Account"
  config.tenant_foreign_key = :account_id
  config.auto_embed = true
  config.embedding_queue = :default
end
```

The null provider stores memories without remote calls. Set `config.null_provider_mode = :deterministic` in tests if you want local deterministic vectors.

For a simple, non-multitenant Rails app:

```ruby
Mempalace.configure do |config|
  config.tenant_mode = :single
end
```

Then `tenant:` is optional:

```ruby
Mempalace.remember(
  wing: "My App",
  room: "architecture",
  content: "Use SQLite first and pgvector later."
)

Mempalace.search(query: "What database did we choose?", wing: "My App")
```

## Remember, Search, Context

```ruby
Mempalace.remember(
  tenant: current_account,
  wing: "AI Receptionist",
  room: "architecture",
  content: "Use Rails 8.1, RubyLLM, OpenRouter, pgvector, Sidekiq...",
  memory_type: "decision"
)

results = Mempalace.search(
  tenant: current_account,
  query: "What stack did we choose?",
  wing: "AI Receptionist",
  limit: 5
)

context = Mempalace.context_for(
  tenant: current_account,
  query: user_message,
  wing: "AI Receptionist",
  max_tokens: 2_000
)
```

Search results return drawer content verbatim:

```ruby
{
  drawer_id: 123,
  content: "Use Rails 8.1, RubyLLM, OpenRouter, pgvector, Sidekiq...",
  wing: "ai-receptionist",
  room: "architecture",
  memory_type: "decision",
  score: 0.91,
  metadata: {}
}
```

## Project Mining

```ruby
Mempalace.mine_project(
  tenant: current_account,
  path: Rails.root,
  wing: "My App"
)
```

The project miner scans readable source files, skips generated/cache directories, chunks text, detects rooms from paths, and stores verbatim chunks as drawers.

## Conversation Mining

```ruby
Mempalace.mine_conversation(
  tenant: current_account,
  wing: "Support Bot",
  conversation: [
    { role: "user", content: "What stack did we pick?", id: "m1" },
    { role: "assistant", content: "Rails, PostgreSQL, pgvector.", id: "m2" }
  ]
)
```

The conversation miner groups user and assistant exchanges where possible and keeps message metadata.

## Embedding Providers

Supported adapters:

- `:null`
- `:ruby_llm`
- `:openai`
- `:openrouter`
- `:ollama`

Embedding failures do not delete drawers. Failed jobs mark the drawer as `failed`, record `embedding_error`, and leave keyword search working.

## pgvector

The migration tries to enable pgvector and creates a vector column/index when available. If pgvector is unavailable, it stores embeddings as JSON text and semantic search gracefully degrades. Keyword search continues to work.

For PostgreSQL:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

## Tenant Isolation

In `:multi` mode, every public read/write API requires `tenant:` unless a tenant resolver is configured. In `:single` mode, the gem uses `config.single_tenant_id` internally so simple apps do not need an `Account` model.

## Rake Tasks

```bash
TENANT_ID=1 bin/rails mempalace:status
TENANT_ID=1 PATH=. bin/rails mempalace:mine_project
TENANT_ID=1 QUERY="appointment safety" bin/rails mempalace:search
TENANT_ID=1 bin/rails mempalace:reembed_failed
```

## Limitations

- v0.1 favors Rails-native storage over ChromaDB compatibility.
- Knowledge graph extraction is manual/API-based, not automatic LLM extraction.
- The simple fallback keyword search is intended for test/dev or non-Postgres setups.
- No UI dashboard or MCP server is included yet.

## Roadmap

See [docs/roadmap.md](docs/roadmap.md).

## Development

```bash
bundle install
bundle exec rake
```

PostgreSQL/pgvector integration coverage is gated behind:

```bash
MEMPALACE_POSTGRES_URL=postgres://user:pass@localhost/mempalace_test bundle exec rake test
```

See [docs/development.md](docs/development.md).
