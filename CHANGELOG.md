# Changelog

## 0.1.0 - Unreleased

- Added Rails engine foundation, configuration, install and migration generators.
- Added tenant-scoped `Wing`, `Room`, `Drawer`, `Closet`, `Fact`, `Tunnel`, and `DiaryEntry` models.
- Added verbatim memory storage, duplicate detection, embedding jobs, keyword/semantic/hybrid search, context builders, miners, closets, facts, tunnels, diary, rake tasks, and docs.
- Added dummy Rails app smoke coverage, mocked HTTP embedding provider tests, RuboCop, and GitHub Actions CI.

## Unreleased

- Add `search_language` (PostgreSQL text search configuration, default `simple`) and `search_query_mode` (`:all`
  default, or `:any` for OR-ed meaningful terms ranked by `ts_rank_cd`). Defaults keep the existing behaviour.
- Install migration builds the `search_vector` trigger with the configured language.
- Tests for the generated tsquery SQL against a real PostgreSQL (`MEMPALACE_POSTGRES_URL`), and a fix for the
  anonymous-class error in the existing PostgreSQL integration test on ActiveRecord 8; `pg` added to the
  development Gemfile.
