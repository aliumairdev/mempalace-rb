# Roadmap

## Phase 1 - Rails Engine and Schema

Complete: gem skeleton, engine, configuration, generators, migrations, models, tenant-safe scopes.

## Phase 2 - Drawer Storage

Complete: `remember`, `remember_exchange`, duplicate detection, content hashes, verbatim drawer persistence.

## Phase 3 - Embeddings

Complete: provider interface, null/test provider, OpenAI/OpenRouter/Ollama/RubyLLM adapters, embed and reindex jobs, failure handling.

## Phase 4 - Search and Context

Complete: keyword search, semantic search, hybrid search, context builder, wake-up builder.

## Phase 5 - Mining

Complete: project miner, file scanner, paragraph chunker, conversation miner, conversation chunker, room and memory-type detection.

## Phase 6 - Parity Features

Complete basic versions: closets, facts, tunnels, diary.

## Future Work

- Stronger PostgreSQL ranking and pgvector SQL search path.
- Optional LLM closet regeneration.
- Automatic fact extraction and fact checking.
- MCP wrapper.
- UI dashboard.
- More adapter-specific integration tests.
