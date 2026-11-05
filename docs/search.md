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

## Language and query mode (PostgreSQL)

By default drawers are indexed with the `simple` text search configuration and a query matches only when every
word appears, spelled exactly (`websearch_to_tsquery`). Two settings change that:

```ruby
Mempalace.configure do |config|
  config.search_language = "english"   # stemming and stop words ("routing" finds "route")
  config.search_query_mode = :any      # meaningful terms OR-ed, ranked by ts_rank_cd
end
```

- `search_language` is the PostgreSQL text search configuration name. The install migration uses it for the
  `search_vector` trigger, so set it before running the migration. Changing it later means re-creating the trigger
  and re-indexing: `UPDATE mempalace_drawers SET content = content;` after replacing the trigger function.
- `search_query_mode`: `:all` (default, unchanged behaviour) or `:any`. With `:any` a query of only stop words
  matches nothing, and results are ranked by how many terms match; apply your own cutoff if you want to hide
  weak matches.
- Both are ignored by the non-PostgreSQL fallback.
