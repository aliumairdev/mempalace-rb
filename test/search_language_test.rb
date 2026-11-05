# frozen_string_literal: true

require "test_helper"

class SearchLanguageTest < MempalaceTest
  def test_defaults_keep_the_existing_behaviour
    assert_equal "simple", Mempalace.configuration.search_language
    assert_equal :all, Mempalace.configuration.search_query_mode
  end

  def test_language_is_validated_because_it_goes_into_sql
    config = Mempalace.configuration
    config.search_language = :english
    assert_equal "english", config.search_language
    ["", "english'; DROP TABLE x; --", "Eng lish", "1english", "a" * 64, nil].each do |bad|
      assert_raises(Mempalace::ConfigurationError, bad.inspect) { config.search_language = bad }
    end
    assert_equal "english", config.search_language
  end

  def test_query_mode_is_validated
    config = Mempalace.configuration
    config.search_query_mode = "any"
    assert_equal :any, config.search_query_mode
    assert_raises(Mempalace::ConfigurationError) { config.search_query_mode = :fuzzy }
    assert_raises(Mempalace::ConfigurationError) { config.search_query_mode = nil }
  end

  def test_tsquery_sql_for_each_mode
    all = Mempalace::Search::KeywordSearch.tsquery_sql(language: "simple", mode: :all, quoted_query: "'q'")
    any = Mempalace::Search::KeywordSearch.tsquery_sql(language: "english", mode: :any, quoted_query: "'q'")
    assert_equal "websearch_to_tsquery('simple', 'q')", all
    assert_equal "replace(plainto_tsquery('english', 'q')::text, ' & ', ' | ')::tsquery", any
  end

  def test_the_install_migration_uses_the_configured_language
    template = File.read(File.expand_path("../lib/generators/mempalace/migrations/templates/create_mempalace_tables.rb.tt", __dir__))
    assert_includes template, "to_tsvector('\#{Mempalace.configuration.search_language}'"
    refute_includes template, "to_tsvector('simple'"
  end

  def test_sqlite_fallback_is_unchanged_by_the_new_settings
    Mempalace.configure do |c|
      c.search_language = "english"
      c.search_query_mode = :any
    end
    account = Account.create!(name: "A")
    Mempalace.remember(tenant: account, wing: "W", room: "R", content: "Keep every message short and direct")
    assert_equal 1, Mempalace.keyword_search(tenant: account, query: "message short").size
  end
end
