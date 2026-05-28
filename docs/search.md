# Search

## Keyword Search

```ruby
Mempalace.keyword_search(tenant: account, query: "pgvector", wing: "AI Receptionist")
```

In `tenant_mode = :single`, omit `tenant:`.

PostgreSQL uses full-text search when `search_vector` exists. Other environments use a safe content-scoring fallback.

## Semantic Search

```ruby
Mempalace.semantic_search(tenant: account, query: "chosen embedding stack")
```

Semantic search embeds the query and compares it with embedded drawers. If embeddings or pgvector are unavailable, it returns an empty result instead of raising.

## Hybrid Search

```ruby
Mempalace.search(tenant: account, query: "appointment safety", limit: 5)
```

Hybrid search dedupes drawer results and combines semantic, keyword, and recency signals.

Supported filters:

- `tenant:` optional in single mode, required in multi mode unless a resolver is configured
- `wing:`
- `room:`
- `memory_type:`
- `source_type:`
- `limit:`
