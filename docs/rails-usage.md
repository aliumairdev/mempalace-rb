# Rails Usage

## Simple App

```ruby
Mempalace.configure do |config|
  config.tenant_mode = :single
end
```

```ruby
drawer = Mempalace.remember(
  wing: "My App",
  room: "architecture",
  content: "Use SQLite first and pgvector later.",
  memory_type: "decision"
)
```

```ruby
results = Mempalace.search(
  query: "What database did we choose?",
  wing: "My App"
)
```

## Multitenant App

```ruby
drawer = Mempalace.remember(
  tenant: current_account,
  wing: "AI Receptionist",
  room: "architecture",
  content: "Use Rails 8.1, RubyLLM, OpenRouter, pgvector, Sidekiq...",
  memory_type: "decision",
  source_type: "manual"
)
```

```ruby
results = Mempalace.search(
  tenant: current_account,
  query: "What stack did we choose?",
  wing: "AI Receptionist",
  limit: 5
)
```

```ruby
prompt_context = Mempalace.context_for(
  tenant: current_account,
  query: params[:message],
  wing: "AI Receptionist",
  max_tokens: 2_000
)
```

In `:multi` mode, all methods are tenant-scoped and accept a tenant object or id. In `:single` mode, the same APIs work without `tenant:`.
