# Architecture

`mempalace-rb` is a Rails engine with ActiveRecord as the source of truth.

## Layers

| Layer | Responsibility |
| --- | --- |
| Public API | `Mempalace.remember`, `search`, `context_for`, miners, taxonomy, facts, diary |
| Services | Tenant-safe orchestration and result formatting |
| Models | Wings, rooms, drawers, closets, facts, tunnels, diary entries |
| Search | Keyword, semantic, and hybrid search over drawers |
| Jobs | Embedding, reindexing, project mining, conversation mining |
| Generators | Initializer and migration installation |

## Memory Shape

- Palace: the installed memory system.
- Wing: tenant-scoped project/person/app/client boundary.
- Room: topic/module/feature within a wing.
- Drawer: original verbatim text and metadata. This is the source of truth.
- Closet: compact pointer/index record that points back to drawers.
- Fact: subject-predicate-object record with validity windows.
- Tunnel: explicit cross-room or cross-wing link.
- DiaryEntry: agent journal entry.

## Storage

PostgreSQL is the production target. The migration uses JSONB and tsvector on PostgreSQL, attempts pgvector when the extension is available, and falls back to JSON/text storage in simpler environments so test and development do not crash.

## Search

Hybrid search combines:

- Semantic score from embeddings when available.
- Keyword score from PostgreSQL full-text search or fallback content scoring.
- Recency boost from `filed_at`.

Drawers remain the source of truth. Closet hits may add or boost candidates, but search can run without closets.

## App Modes

`mempalace-rb` supports both simple and multitenant apps:

- `tenant_mode = :single` stores all memories under `single_tenant_id`, so apps without an `Account` model can omit `tenant:`.
- `tenant_mode = :multi` requires an explicit tenant or resolver and scopes every read/write through the configured tenant foreign key, defaulting to `account_id`.

In both modes, model scopes and service objects resolve a concrete tenant id through `Mempalace::Tenant` before querying.
