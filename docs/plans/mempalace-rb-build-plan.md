# mempalace-rb Build Plan

Audit source: MemPalace upstream `6957c7e` (`3.3.6`, cloned 2026-05-28). This plan is planning-only; it does not implement the gem.

## 1. Product Goal

Build `mempalace-rb` as a Rails-native long-term memory layer for AI agents and Rails apps. It should store original verbatim memory text, isolate every memory by tenant, and retrieve prompt-ready context using PostgreSQL full-text search plus pgvector semantic search.

The desired Rails API:

```ruby
Mempalace.remember(
  tenant: current_account,
  wing: "AI Receptionist",
  room: "architecture",
  content: "Use Rails 8.1, RubyLLM, OpenRouter, pgvector, Sidekiq..."
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

## 2. MemPalace Repo Findings

### Files inspected

Core docs and packaging:

| Area | Files |
| --- | --- |
| Product docs | `README.md`, `mempalace/README.md`, `CHANGELOG.md`, `ROADMAP.md`, `docs/CLOSETS.md`, `docs/schema.sql`, `docs/format-coverage.md` |
| Package/CLI | `pyproject.toml`, `mempalace/cli.py`, `website/reference/cli.md` |
| Storage | `mempalace/backends/base.py`, `mempalace/backends/chroma.py`, `mempalace/palace.py` |
| Mining | `mempalace/miner.py`, `mempalace/convo_miner.py`, `mempalace/convo_scanner.py`, `mempalace/normalize.py`, `mempalace/format_miner.py` |
| Retrieval | `mempalace/searcher.py`, `mempalace/layers.py`, `mempalace/dedup.py` |
| Graph/memory types | `mempalace/knowledge_graph.py`, `mempalace/palace_graph.py`, `mempalace/hallways.py`, `mempalace/general_extractor.py` |
| Agents/MCP | `mempalace/mcp_server.py`, `website/reference/mcp-tools.md`, `mempalace/diary_ingest.py`, `mempalace/fact_checker.py` |
| Extensibility | `docs/rfcs/002-source-adapter-plugin-spec.md`, `mempalace/sources/base.py`, `mempalace/sources/context.py`, `mempalace/sources/registry.py` |
| Tests/examples | `tests/test_readme_claims.py`, `tests/test_closets.py`, `tests/test_hybrid_search.py`, `tests/test_convo_miner.py`, `tests/test_mcp_server.py`, `examples/basic_mining.py`, `examples/convo_import.py` |

### What MemPalace does

MemPalace is a local-first Python CLI/MCP memory system. It stores verbatim text in ChromaDB collections, routes content into wings and rooms, creates drawer chunks, adds compact closet pointer records for project-mined content, searches with semantic vectors plus BM25-style keyword reranking, and exposes memory through CLI and MCP tools. It also includes conversation mining, office document extraction, wake-up context, a temporal knowledge graph, tunnels, diary tools, hooks, repair tools, and duplicate detection.

### Verified core product logic

| Concept | Verified implementation |
| --- | --- |
| Verbatim drawers | Project and conversation miners store original chunk text in `mempalace_drawers`; comments explicitly say no summaries. |
| Wings/rooms | Stored in drawer metadata as `wing` and `room`; room detection uses path, filename, and keyword scoring. |
| Drawers | Deterministic IDs from source file plus chunk index; chunks carry `source_file`, `chunk_index`, `filed_at`, `normalize_version`, optional line ranges, hall, and entities. |
| Closets | `mempalace_closets` Chroma collection; project miner builds compact pointer lines `topic|entities|date:lines|->drawer_ids`. |
| Search | `searcher.py` always queries drawers, optionally boosts with closet hits, reranks with BM25 over candidates, and can union BM25-only SQLite/FTS5 candidates. |
| Project mining | Scans readable files, respects `.gitignore`, skips generated folders, chunks by paragraph/line boundaries, detects rooms, purges stale drawers, and upserts batches. |
| Conversation mining | Normalizes Claude Code, Codex, Gemini, Claude.ai, ChatGPT, Slack, and plain text; chunks by user/assistant exchange when possible. |
| Memory type detection | `general_extractor.py` uses heuristic patterns for decision, preference, milestone, problem, and emotional memories. |
| Knowledge graph | SQLite-backed entities/triples with temporal validity windows, invalidation, timeline, and stats. |
| Tunnels/graph | Room graph and explicit/topic/entity tunnels exist; tunnels are JSON-backed and validated for real explicit rooms. |
| Wake-up context | `layers.py` has L0 identity, L1 essential story, L2 on-demand recall, and L3 deep search. L1 is heuristic formatting over top drawers, not a full summarization pipeline. |
| Duplicate detection | MCP duplicate check uses vector similarity; `dedup.py` groups by source and greedily removes near duplicates. |
| MCP | Actual `TOOLS` registry contains 30 tools. README says 29, while the MCP reference says 30, so docs are slightly inconsistent at this commit. |
| Source adapters | RFC 002 and `mempalace/sources/*` define a contract and registry, but comments say first-party miners are not migrated yet. This is scaffolding, not the active ingest path. |

### Python/ChromaDB implementation details

These should not be copied directly into the Rails gem:

| Detail | Why redesign |
| --- | --- |
| ChromaDB collections | Rails version should use Postgres, ActiveRecord, pgvector, and native full-text search. |
| Chroma SQLite/FTS5 repair logic | Rails version should rely on Postgres indexes, migrations, and operational checks. |
| ONNX embedding function binding | Rails should use pluggable Ruby provider adapters. Local ONNX can be future work. |
| Filesystem palace path under `~/.mempalace` | Rails apps need database-backed tenant isolation, not user-home local state. |
| Python CLI/MCP entry points | Rails version needs Ruby APIs, Rails generators, ActiveJob, and Rake tasks first. |
| JSON sidecars for tunnels/config | Rails version should store durable state in relational tables. |
| File locks | Rails version should use DB uniqueness, advisory locks where needed, and idempotent jobs. |

### Concepts worth adapting

| Keep conceptually | Rails-native adaptation |
| --- | --- |
| Verbatim storage | `Mempalace::Drawer.content` is the source of truth. Search/context returns original text. |
| Wings and rooms | First-class ActiveRecord models scoped to tenant. |
| Drawers | First-class chunks with hashes, source metadata, FTS vector, and embedding status. |
| Closets | Future compact pointer/index table that points back to drawers; not required for v0.1. |
| Hybrid retrieval | Candidate union from pgvector and Postgres full-text, then normalized score merge. |
| Layered context | `context_for` and `wake_up` produce token-budgeted prompt context. |
| Idempotent mining | Content hashes, source identity, chunk index, and unique indexes. |
| Memory types/halls | Start with heuristic memory type detection; later add LLM classification. |
| KG/tunnels | Good v0.2+ relational features after drawer/search foundation is stable. |

## 3. What We Will Copy Conceptually

- The palace metaphor: palace, wing, room, drawer, closet, hall, tunnel.
- Verbatim memory as the durable primary artifact.
- Deterministic chunk identity and idempotent ingestion.
- Layered retrieval: status/taxonomy, search, context, wake-up.
- Hybrid search that treats semantic and keyword retrieval as complementary.
- A compact pointer/index layer later, but only after drawers/search are stable.
- Clear separation between raw memory storage and derived indexes.

## 4. What We Will Redesign for Rails

- Storage becomes ActiveRecord tables in the host app database.
- Search becomes Postgres `tsvector` plus pgvector HNSW indexes.
- Tenant isolation is mandatory and explicit on every public call.
- Jobs use ActiveJob, with Sidekiq as an optional adapter.
- Embeddings are provider adapters, not Chroma embedding functions.
- Generators install migrations and an initializer.
- Rake tasks replace Python CLI commands for Rails apps.
- Future MCP should wrap the Ruby API, not drive the core design.

## 5. Target Users and Use Cases

| User | Needs |
| --- | --- |
| Rails SaaS builders | Tenant-safe AI memory for accounts, teams, projects, and support workflows. |
| AI agent builders | Durable project/conversation memory with prompt-ready context. |
| Open-source Rails maintainers | Installable engine, migrations, documented APIs, and reliable tests. |
| Internal tool teams | Searchable institutional memory from project files, tickets, chats, or app messages. |

Core use cases:

- Store one memory or one conversation exchange.
- Search tenant-scoped memories by semantic meaning and exact terms.
- Build a bounded context block for an AI prompt.
- Mine project files into wings/rooms/drawers.
- Mine Rails conversation/message records into verbatim exchange drawers.
- Re-embed failed or stale drawers in background jobs.
- Inspect wings, rooms, status, and taxonomy.

## 6. Architecture Overview

```text
mempalace-rb
  Ruby facade
    Mempalace.remember/search/context_for/wake_up
  Rails engine
    ActiveRecord models
    migrations
    generators
    ActiveJob jobs
    Rake tasks
  Storage
    PostgreSQL
    pgvector
    PostgreSQL full-text search
  Services
    ingestion/mining
    chunking
    search
    context builder
    embedding providers
    tenant resolver
```

Primary v0.1 flow:

```text
remember/mine
  -> resolve tenant
  -> find_or_create wing and room
  -> normalize minimal metadata
  -> hash content
  -> save drawer verbatim
  -> enqueue EmbedDrawerJob

search/context_for
  -> resolve tenant
  -> build scoped filters
  -> semantic candidates from pgvector
  -> keyword candidates from tsvector
  -> merge, normalize, rank
  -> return verbatim drawer content
```

## 7. Gem and Rails Engine Structure

Proposed gem layout:

```text
mempalace-rb
  lib/
    mempalace.rb
    mempalace/configuration.rb
    mempalace/engine.rb
    mempalace/errors.rb
    mempalace/models/
      wing.rb
      room.rb
      drawer.rb
      closet.rb
      fact.rb
      tunnel.rb
    mempalace/services/
      remember.rb
      remember_exchange.rb
      search.rb
      context_builder.rb
      wake_up.rb
      duplicate_check.rb
    mempalace/search/
      keyword_search.rb
      semantic_search.rb
      hybrid_search.rb
      scorer.rb
    mempalace/embedding/
      base_provider.rb
      ruby_llm_provider.rb
      open_router_provider.rb
      open_ai_provider.rb
      ollama_provider.rb
    mempalace/miners/
      project_miner.rb
      conversation_miner.rb
      file_scanner.rb
    mempalace/chunking/
      paragraph_chunker.rb
      conversation_chunker.rb
    mempalace/detection/
      room_detector.rb
      memory_type_detector.rb
    mempalace/jobs/
      embed_drawer_job.rb
      mine_project_job.rb
      mine_conversation_job.rb
      reindex_drawer_job.rb
  app/
    models/mempalace/
    jobs/mempalace/
  db/migrate/
  lib/generators/mempalace/install/
  lib/generators/mempalace/migrations/
  lib/tasks/mempalace.rake
  docs/
```

Engine rules:

- Use `isolate_namespace Mempalace`.
- Do not assume a specific host `Account` class beyond configured tenant key.
- Keep public services independent of controllers or UI.
- Do not add dashboard/UI in v0.1.

## 8. Database Schema

### MVP models

| Model | Phase | Purpose |
| --- | --- | --- |
| `Mempalace::Wing` | v0.1 | Tenant-scoped memory domain, project, app, person, or client. |
| `Mempalace::Room` | v0.1 | Tenant-scoped topic/module/feature inside a wing. |
| `Mempalace::Drawer` | v0.1 | Verbatim memory chunk plus search indexes and embedding state. |

### Later models

| Model | Phase | Purpose |
| --- | --- | --- |
| `Mempalace::Closet` | v0.2 | Compact searchable pointer/index records back to drawers. |
| `Mempalace::Fact` | v0.2 | Subject-predicate-object facts with validity windows. |
| `Mempalace::Tunnel` | v0.2 | Cross-wing/cross-room links. |
| `Mempalace::DiaryEntry` | v0.3 | Agent diary entries, likely backed by drawers plus convenience model. |

### Migration prerequisites

```ruby
enable_extension "vector"
```

If the host app has not enabled `pgcrypto`, use bigint IDs by default. UUID support can be generated with `config.primary_key_type = :uuid`.

### `mempalace_wings`

```ruby
create_table :mempalace_wings do |t|
  t.bigint :account_id, null: false
  t.string :name, null: false
  t.string :slug, null: false
  t.jsonb :metadata, null: false, default: {}
  t.timestamps
end

add_index :mempalace_wings, [:account_id, :slug], unique: true
add_index :mempalace_wings, :account_id
```

### `mempalace_rooms`

```ruby
create_table :mempalace_rooms do |t|
  t.bigint :account_id, null: false
  t.references :wing, null: false, foreign_key: { to_table: :mempalace_wings }
  t.string :name, null: false
  t.string :slug, null: false
  t.jsonb :metadata, null: false, default: {}
  t.timestamps
end

add_index :mempalace_rooms, [:account_id, :wing_id, :slug], unique: true
add_index :mempalace_rooms, [:account_id, :wing_id]
```

### `mempalace_drawers`

```ruby
create_table :mempalace_drawers do |t|
  t.bigint :account_id, null: false
  t.references :wing, null: false, foreign_key: { to_table: :mempalace_wings }
  t.references :room, null: false, foreign_key: { to_table: :mempalace_rooms }

  t.text :content, null: false
  t.string :content_sha256, null: false
  t.string :normalized_content_sha256, null: false

  t.string :memory_type, null: false, default: "general"
  t.string :source_type
  t.string :source_id
  t.string :source_file
  t.integer :chunk_index, null: false, default: 0
  t.integer :line_start
  t.integer :line_end
  t.datetime :filed_at, null: false
  t.jsonb :metadata, null: false, default: {}

  # Generated by SQL, not by Ruby callbacks.
  t.column :search_vector, :tsvector

  # Dimension is generated from config.vector_dimensions.
  t.vector :embedding, limit: 1536
  t.string :embedding_model
  t.string :embedding_status, null: false, default: "pending"
  t.text :embedding_error
  t.datetime :embedded_at

  t.timestamps
end

add_index :mempalace_drawers, [:account_id, :content_sha256], unique: true
add_index :mempalace_drawers, [:account_id, :normalized_content_sha256]
add_index :mempalace_drawers, [:account_id, :wing_id, :room_id]
add_index :mempalace_drawers, [:account_id, :source_type, :source_id, :chunk_index],
  name: "idx_mempalace_drawers_source"
add_index :mempalace_drawers, [:account_id, :memory_type]
add_index :mempalace_drawers, [:account_id, :source_type]
add_index :mempalace_drawers, :metadata, using: :gin
add_index :mempalace_drawers, :search_vector, using: :gin

execute <<~SQL
  CREATE INDEX idx_mempalace_drawers_embedding_hnsw
  ON mempalace_drawers
  USING hnsw (embedding vector_cosine_ops)
  WHERE embedding IS NOT NULL AND embedding_status = 'embedded';
SQL
```

Search vector maintenance:

```sql
CREATE FUNCTION mempalace_drawers_search_vector_update() RETURNS trigger AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('simple', coalesce(NEW.content, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(NEW.memory_type, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(NEW.source_file, '')), 'C');
  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER mempalace_drawers_search_vector_before_write
BEFORE INSERT OR UPDATE OF content, memory_type, source_file
ON mempalace_drawers
FOR EACH ROW EXECUTE FUNCTION mempalace_drawers_search_vector_update();
```

### Future tables

`mempalace_closets`: tenant, wing, room, drawer references or `drawer_ids`, compact pointer text, metadata, search vector, optional embedding.

`mempalace_facts`: tenant, subject, predicate, object, valid_from, valid_to, confidence, source drawer reference, metadata.

`mempalace_tunnels`: tenant, source wing/room/drawer, target wing/room/drawer, kind, label, metadata, strength, timestamps.

## 9. Public API

The API must support both normal single-space Rails apps and multitenant SaaS apps. In `tenant_mode = :single`, methods may omit `tenant:` and the gem stores data under `single_tenant_id`. In `tenant_mode = :multi`, methods require `tenant:` unless a configured resolver is explicitly enabled. Passing a tenant model object is preferred in multi mode; IDs are allowed when callers intentionally manage tenant ids.

```ruby
Mempalace.configure do |config|
  config.embedding_provider = :ruby_llm
  config.embedding_model = "text-embedding-3-small"
  config.vector_dimensions = 1536
  config.tenant_mode = :multi
  config.tenant_model = "Account"
  config.tenant_foreign_key = :account_id
  config.single_tenant_id = 0
  config.default_chunk_size = 800
  config.default_chunk_overlap = 100
end
```

| Method | Purpose | Example input | Example output | Tenant safety |
| --- | --- | --- | --- | --- |
| `configure` | Set gem options. | `Mempalace.configure { |c| c.tenant_foreign_key = :account_id }` | config object | Does not query data. |
| `remember` | Store one verbatim memory. | `tenant:, wing:, room:, content:` or omit `tenant:` in single mode | `{ drawer_id:, duplicate:, embedding_status: }` | Creates/fetches wing, room, drawer under resolved tenant only. |
| `remember_exchange` | Store user/assistant exchange as one drawer or chunks. | `tenant:, wing:, user:, assistant:, occurred_at:` | `{ drawer_ids:, exchange_id: }` | Uses resolved tenant and stamps message IDs in metadata. |
| `search` | Hybrid search. | `tenant:, query:, wing:, room:, limit:` | array of result hashes with verbatim `content` | All candidate queries begin with resolved tenant scope. |
| `keyword_search` | Postgres FTS only. | `tenant:, query:, memory_type:` | same result shape | No unscoped FTS calls. |
| `semantic_search` | pgvector only. | `tenant:, query:, limit:` | same result shape | Filters before/inside vector candidate SQL. |
| `context_for` | Prompt-ready context under token budget. | `tenant:, query:, max_tokens:` | string or context object | Uses `search` and preserves resolved tenant scope. |
| `wake_up` | Layered startup context for agent/session. | `tenant:, wing:, max_tokens:` | context string with recent/important drawers | Tenant-scoped recent/top drawer selection. |
| `mine_project` | Scan files and store chunks. | `tenant:, path:, wing:, async: true` | `{ job_id: }` or report | Every drawer write uses resolved tenant. |
| `mine_conversation` | Mine AR messages or transcript files. | `tenant:, relation:, wing:` | `{ job_id: }` or report | Relation is checked for tenant compatibility when configured. |
| `duplicate?` | Exact/near duplicate check. | `tenant:, content:, threshold:` | `{ duplicate:, matches: [] }` | Searches only resolved-tenant drawers. |
| `status` | Counts and operational state. | `tenant:` optional in single mode | `{ drawers:, wings:, pending_embeddings: }` | Tenant counts only. |
| `list_wings` | List wing names/counts. | `tenant:` optional in single mode | `[{ name:, slug:, drawer_count: }]` | Tenant scope on wings and drawers. |
| `list_rooms` | List rooms, optionally in wing. | `tenant:, wing:` | `[{ name:, slug:, drawer_count: }]` | Tenant and wing scope. |
| `taxonomy` | Wing -> room tree. | `tenant:` optional in single mode | `{ "AI Receptionist" => { "architecture" => 3 } }` | Tenant aggregation only. |

Canonical result shape:

```ruby
[
  {
    drawer_id: "123",
    content: "Use Rails 8.1, RubyLLM, OpenRouter, pgvector, Sidekiq...",
    wing: "AI Receptionist",
    room: "architecture",
    memory_type: "decision",
    score: 0.91,
    metadata: {}
  }
]
```

## 10. Search Architecture

### Filters

All search variants support:

```ruby
tenant:
wing:
room:
memory_type:
source_type:
limit:
```

### Keyword search

Use Postgres full-text search:

```sql
websearch_to_tsquery('simple', :query)
ts_rank_cd(search_vector, query)
```

Keyword search should work even when embedding providers are unavailable.

### Semantic search

Use pgvector cosine distance:

```sql
1 - (embedding <=> :query_embedding) AS semantic_score
```

Only include drawers with `embedding_status = 'embedded'` and the current configured embedding model unless `include_stale_embeddings` is enabled.

### Hybrid search

Use candidate union:

1. Fetch semantic top `limit * 4`.
2. Fetch keyword top `limit * 4`.
3. Merge by drawer ID.
4. Normalize each component to 0..1.
5. Apply filters and final score.

Initial v0.1 formula:

```text
final_score =
  semantic_score * 0.70 +
  keyword_score  * 0.25 +
  recency_score  * 0.05
```

Recency score can be simple exponential decay from `filed_at`, capped so older decisive memories still win when semantic/keyword scores are strong.

Future v0.2 closet boost:

```text
final_score =
  semantic_score * 0.62 +
  keyword_score  * 0.23 +
  closet_score   * 0.10 +
  recency_score  * 0.05
```

### Failure modes

- If embedding fails for the query, run keyword search only.
- If no embeddings exist, run keyword search only.
- If FTS query parses poorly, fall back to `plainto_tsquery`.
- Always return original drawer content, never closet text alone.

## 11. Ingestion and Mining

Components:

```ruby
Mempalace::Miners::ProjectMiner
Mempalace::Miners::ConversationMiner
Mempalace::Miners::FileScanner
Mempalace::Chunking::ParagraphChunker
Mempalace::Chunking::ConversationChunker
Mempalace::Detection::RoomDetector
Mempalace::Detection::MemoryTypeDetector
```

### Project miner

Responsibilities:

- Scan a project directory.
- Respect `.gitignore` when reasonable.
- Prefer `git ls-files -co --exclude-standard` inside Git repos; fall back to Ruby file walking.
- Skip generated/cache folders:
  `.git`, `node_modules`, `tmp`, `log`, `storage`, `vendor/bundle`, `.next`, `dist`, `build`, `coverage`.
- Support readable extensions:
  `.rb`, `.md`, `.txt`, `.yml`, `.yaml`, `.json`, `.js`, `.ts`, `.tsx`, `.jsx`, `.sql`, `.sh`, `.erb`, `.haml`, `.slim`.
- Allow custom extensions in config.
- Skip oversized files by configurable max bytes.
- Chunk content into drawer-sized paragraphs with overlap.
- Detect room from path, filename, then content keywords.
- Detect memory type from content heuristics.
- Store verbatim chunks as drawers.
- Enqueue embeddings.

### Conversation miner

Responsibilities:

- Support Rails message/conversation models via relation or class config.
- Support plain text transcripts in v0.1.
- Support JSON/JSONL transcript imports later.
- Group user and assistant exchange where possible.
- Preserve timestamps, conversation IDs, and message IDs in metadata.
- Store verbatim exchange text as drawers.

Example AR input:

```ruby
Mempalace.mine_conversation(
  tenant: account,
  relation: account.chat_messages.order(:created_at),
  wing: "Support Agent",
  role_column: :role,
  content_column: :content,
  timestamp_column: :created_at
)
```

## 12. Embedding Providers

Adapter contract:

```ruby
class Mempalace::Embedding::BaseProvider
  def embed(text)
    raise NotImplementedError
  end
end
```

Providers:

| Provider | Purpose |
| --- | --- |
| `RubyLlmProvider` | Default Rails-friendly abstraction when `ruby_llm` is present. |
| `OpenRouterProvider` | Direct OpenRouter embeddings API support. |
| `OpenAiProvider` | Direct OpenAI embeddings API support. |
| `OllamaProvider` | Local embeddings for privacy-sensitive installs. |

Configuration:

```ruby
Mempalace.configure do |config|
  config.embedding_provider = :ruby_llm
  config.embedding_model = "text-embedding-3-small"
  config.vector_dimensions = 1536
  config.embedding_timeout = 30.seconds
  config.embedding_retries = 3
end
```

Embedding failure behavior:

- Drawer is still saved.
- `embedding_status` becomes `failed`.
- `embedding_error` stores a concise error message.
- Keyword search still works.
- `Mempalace::EmbedDrawerJob` can retry later.
- Search should never pretend an unembedded drawer was semantically scored.

## 13. Tenant Isolation

The gem supports two app modes:

- `:single` for apps with one memory space and no account model. APIs may omit `tenant:` and resolve to `config.single_tenant_id`.
- `:multi` for SaaS/account/client scoped apps. APIs require `tenant:` unless a resolver is configured.

Tenant isolation in multi mode is non-negotiable.

Rules:

- Every public read/write method resolves a tenant id before querying or writing.
- In multi mode, the tenant object is resolved to the configured foreign key.
- `Wing`, `Room`, and `Drawer` all carry the tenant foreign key.
- Service objects reject tenant mismatches between wing, room, and drawer.
- No model method should call `unscoped` in normal application paths.
- Unique indexes are tenant-scoped.
- Search SQL must include tenant predicates in every candidate query.
- Tests must prove tenant A can never see tenant B memories.

Recommended model safeguards:

```ruby
scope :for_tenant, ->(tenant) { where(Mempalace.config.tenant_foreign_key => Mempalace.tenant_id_for(tenant)) }

validates :account_id, presence: true
validate :wing_matches_tenant
validate :room_matches_tenant
```

Optional default tenant resolver:

```ruby
config.tenant_resolver = -> { Current.account }
```

Even with a resolver, methods should accept explicit `tenant:` and tests should cover both paths.

### Error handling and safety

Core errors should be typed and rescue-friendly:

| Error | When raised |
| --- | --- |
| `Mempalace::MissingTenantError` | Public API call has no tenant and no resolver. |
| `Mempalace::TenantMismatchError` | Wing, room, or drawer belongs to another tenant. |
| `Mempalace::EmbeddingError` | Provider fails outside background job context. |
| `Mempalace::ConfigurationError` | Missing provider, invalid vector dimensions, or invalid tenant config. |
| `Mempalace::MiningError` | Project/conversation mining cannot proceed. |

Safety defaults:

- Save drawers even when embeddings fail.
- Limit content size per drawer and chunk before embedding.
- Store concise provider errors, not secrets or full HTTP payloads.
- Never log full drawer content by default.
- Use idempotent writes and unique indexes for duplicate prevention.
- Avoid destructive rake tasks without explicit flags.
- Treat empty search results as empty arrays, not exceptions.

## 14. Background Jobs

Jobs:

| Job | Purpose |
| --- | --- |
| `Mempalace::EmbedDrawerJob` | Embed one drawer and update status. |
| `Mempalace::MineProjectJob` | Run project miner in background. |
| `Mempalace::MineConversationJob` | Run conversation miner in background. |
| `Mempalace::ReindexDrawerJob` | Refresh FTS/embedding for one drawer after content/model changes. |

Job rules:

- Use ActiveJob only in the public gem.
- Let host apps choose Sidekiq, Solid Queue, GoodJob, etc.
- Store retries and errors on drawer/job metadata.
- Make jobs idempotent by drawer ID and content hash.
- Do not pass tenant objects through jobs; pass tenant ID and validate on load.

## 15. Generators and Rake Tasks

Generators:

```bash
bin/rails generate mempalace:install
bin/rails generate mempalace:migrations
```

Install generator creates:

```ruby
# config/initializers/mempalace.rb
Mempalace.configure do |config|
  config.embedding_provider = :ruby_llm
  config.embedding_model = "text-embedding-3-small"
  config.vector_dimensions = 1536
  config.tenant_mode = :multi
  config.tenant_model = "Account"
  config.tenant_foreign_key = :account_id
  config.single_tenant_id = 0
  config.default_chunk_size = 800
  config.default_chunk_overlap = 100
end
```

Rake tasks:

```bash
bin/rails mempalace:status TENANT_ID=1
bin/rails mempalace:mine_project TENANT_ID=1 PATH=.
bin/rails mempalace:search TENANT_ID=1 QUERY="appointment safety"
bin/rails mempalace:reembed_failed TENANT_ID=1
```

Rake tasks must require tenant input in multi mode unless a tenant resolver is explicitly configured for CLI use. In single mode, tasks use `single_tenant_id`.

## 16. Testing Strategy

Use a dummy Rails app and Minitest by default. The critical tests are safety and retrieval correctness, not UI.

Test coverage:

- Configuration defaults and overrides.
- Engine boot in dummy Rails app.
- Migrations on PostgreSQL with pgvector enabled.
- Model validations and associations.
- Tenant isolation and cross-tenant leakage.
- `remember` API.
- `remember_exchange` API.
- Exact duplicate detection by hash.
- Near duplicate detection by semantic score when embeddings exist.
- Keyword search.
- Semantic search.
- Hybrid score merging.
- Embedding failure handling.
- Background jobs and retries.
- Project miner scanning, skip rules, chunking, room detection.
- Conversation miner grouping and metadata.
- Generators.
- Rake tasks.
- Search with unembedded drawers.
- Search with stale embedding model.

Use fake embedding providers in tests:

```ruby
class FakeEmbeddingProvider
  def embed(text)
    Array.new(1536, 0.0).tap { |v| v[0] = text.length / 1000.0 }
  end
end
```

## 17. Documentation Plan

Docs:

```text
README.md
docs/installation.md
docs/configuration.md
docs/rails-usage.md
docs/search.md
docs/mining-projects.md
docs/mining-conversations.md
docs/tenant-isolation.md
docs/embedding-providers.md
docs/roadmap.md
```

README must include:

- What the gem is.
- Why verbatim memory matters.
- Quick install.
- Quick usage.
- Rails example.
- AI agent example.
- Tenant isolation warning.
- Limitations.
- Roadmap.

## 18. MVP Scope

v0.1 definition:

```text
A Rails app can install the gem, create tenant-scoped wings/rooms/drawers,
store verbatim memories, generate embeddings, run keyword/semantic/hybrid
search, and build prompt-ready context.
```

Include in v0.1:

- Rails engine.
- Migrations.
- `Wing`, `Room`, `Drawer`.
- Install generator.
- Initializer.
- `remember`.
- `remember_exchange`.
- `search`.
- `keyword_search`.
- `semantic_search`.
- `context_for`.
- `wake_up` basic version.
- `status`, `list_wings`, `list_rooms`, `taxonomy`.
- Embedding provider interface.
- One working provider.
- Embedding failure handling.
- Basic project miner.
- Basic conversation miner.
- Tenant isolation tests.
- README.

Non-goals for v0.1:

- MCP server.
- Full knowledge graph.
- Tunnels.
- Diary.
- Closets.
- UI dashboard.
- Multi-vector-store support.
- ChromaDB integration.
- LLM closet regeneration.
- Complex fact checker.
- Office document extraction.

## 19. Roadmap

### Phase 0 - Repo audit and final architecture

Deliverables:

- `docs/plans/mempalace-rb-build-plan.md`
- `docs/architecture.md`
- `docs/roadmap.md`

### Phase 1 - Rails engine and schema

Deliverables:

- Gem skeleton.
- Rails engine.
- Install generator.
- Migrations.
- Models.
- Tenant isolation tests.

### Phase 2 - Remember and drawer storage

Deliverables:

- `Mempalace.remember`.
- `Mempalace.remember_exchange`.
- Duplicate detection.
- Content hashing.
- Drawer CRUD.
- Keyword index.

### Phase 3 - Embeddings and semantic search

Deliverables:

- Embedding provider interface.
- At least one provider.
- `EmbedDrawerJob`.
- pgvector search.
- Embedding failure handling.

### Phase 4 - Hybrid search and context builder

Deliverables:

- `Mempalace.search`.
- `Mempalace.context_for`.
- `Mempalace.wake_up`.
- Token budget handling.
- Result formatting.

### Phase 5 - Project and conversation mining

Deliverables:

- Project miner.
- File scanner.
- Chunkers.
- Room detector.
- Conversation miner.
- Rake tasks.

### Phase 6 - Optional MemPalace parity features

Deliverables:

- Closets.
- Facts/knowledge graph.
- Tunnels.
- Diary.
- MCP wrapper.

## 20. Example Rails Usage

Install:

```bash
bundle add mempalace-rb
bin/rails generate mempalace:install
bin/rails generate mempalace:migrations
bin/rails db:migrate
```

Store memory:

```ruby
Mempalace.remember(
  tenant: current_account,
  wing: "AI Receptionist",
  room: "architecture",
  memory_type: "decision",
  content: "Use Rails 8.1, RubyLLM, OpenRouter, pgvector, and Sidekiq for the receptionist agent."
)
```

Search:

```ruby
Mempalace.search(
  tenant: current_account,
  query: "What stack did we choose for the receptionist?",
  wing: "AI Receptionist",
  limit: 5
)
```

Build prompt context:

```ruby
context = Mempalace.context_for(
  tenant: current_account,
  query: params[:message],
  wing: "AI Receptionist",
  max_tokens: 2_000
)
```

## 21. Example AI Agent Usage

```ruby
class ReceptionistAgent
  def initialize(account)
    @account = account
  end

  def reply(user_message)
    memory_context = Mempalace.context_for(
      tenant: @account,
      wing: "AI Receptionist",
      query: user_message,
      max_tokens: 2_000
    )

    RubyLLM.chat.with_instructions(<<~PROMPT).ask(user_message)
      You are the receptionist agent for this account.

      Relevant long-term memory:
      #{memory_context}
    PROMPT
  end

  def remember_exchange(user_message, assistant_message)
    Mempalace.remember_exchange(
      tenant: @account,
      wing: "AI Receptionist",
      room: "conversations",
      user: user_message,
      assistant: assistant_message,
      occurred_at: Time.current
    )
  end
end
```

## 22. Open Questions

1. Should v0.1 default to `ruby_llm` embeddings or direct OpenAI-compatible HTTP?
2. Should generated migrations default to bigint tenant keys or ask for UUID at install time?
3. Should `content_sha256` uniqueness be tenant-wide or source-scoped? Tenant-wide prevents exact duplicates; source-scoped preserves repeated quotes from different sources.
4. Should `context_for` return a string by default or a structured object with citations and token counts?
5. Should project mining be included in the first gem release or ship right after core remember/search?
6. Which token estimator should be used in v0.1 without adding a heavy tokenizer dependency?
7. How strict should source-file path storage be for privacy? Basename-only is safer; full path improves debugging.
