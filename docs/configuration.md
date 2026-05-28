# Configuration

```ruby
Mempalace.configure do |config|
  config.embedding_provider = :null
  config.embedding_model = nil
  config.vector_dimensions = 1536
  config.tenant_mode = :multi
  config.tenant_model = "Account"
  config.tenant_foreign_key = :account_id
  config.default_chunk_size = 800
  config.default_chunk_overlap = 100
  config.auto_embed = true
  config.embedding_queue = :default
end
```

## Embeddings

Use `:null` for no remote calls, `:openai`, `:openrouter`, `:ollama`, or `:ruby_llm` for provider-backed vectors.

For tests:

```ruby
config.embedding_provider = :null
config.null_provider_mode = :deterministic
```

## Tenant

The default mode is `:multi`, which requires `tenant:` on public API calls.

```ruby
config.tenant_mode = :multi
config.tenant_model = "Account"
config.tenant_foreign_key = :account_id
```

For simple apps without accounts or tenants:

```ruby
config.tenant_mode = :single
config.single_tenant_id = 0
```

In `:single` mode, calls can omit `tenant:` and the gem stores all memories under `single_tenant_id`.
