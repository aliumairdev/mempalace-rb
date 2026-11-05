# frozen_string_literal: true

require "test_helper"

class PgSearchSqlBase < ActiveRecord::Base
  self.abstract_class = true
end

# Runs the generated SQL against a real PostgreSQL (the rest of the suite uses SQLite). Set
# MEMPALACE_POSTGRES_URL, e.g. postgres:///mempalace_test.
class PostgresSearchSqlTest < Minitest::Test
  def setup
    @url = ENV.fetch("MEMPALACE_POSTGRES_URL", nil)
    skip "set MEMPALACE_POSTGRES_URL to run the PostgreSQL search SQL tests" if @url.to_s.empty?
    PgSearchSqlBase.establish_connection(@url)
    @conn = PgSearchSqlBase.connection
  end

  def teardown
    PgSearchSqlBase.connection_pool.disconnect! if @conn
  end

  def matches?(language, mode, query, text)
    tsquery = Mempalace::Search::KeywordSearch.tsquery_sql(language: language, mode: mode, quoted_query: @conn.quote(query))
    @conn.select_value("SELECT to_tsvector('#{language}', #{@conn.quote(text)}) @@ #{tsquery}")
  end

  def test_all_mode_with_simple_language_needs_every_exact_word
    assert matches?("simple", :all, "short direct", "Keep every message short and direct")
    refute matches?("simple", :all, "write a short direct message", "Keep every message short and direct")
    refute matches?("simple", :all, "routing", "we route leads")
  end

  def test_any_mode_with_english_finds_natural_requests_and_stems
    assert matches?("english", :any, "write a short direct message", "Keep every message short and direct")
    assert matches?("english", :any, "routing", "we route leads")
    refute matches?("english", :any, "weather in Paris", "Keep every message short and direct")
  end

  def test_a_query_of_only_stop_words_matches_nothing_in_any_mode
    refute matches?("english", :any, "what is the", "what is the plan")
  end

  def test_odd_characters_are_data_not_syntax
    ["a & b", "a | b", "'quoted'", "x:*", "!x", "(x", "\"x y\""].each do |q|
      matches?("english", :any, q, "x y a b") # must not raise
    end
  end

  def test_the_language_names_used_exist_in_this_server
    langs = @conn.select_values("SELECT cfgname FROM pg_ts_config")
    assert_includes langs, "simple"
    assert_includes langs, "english"
  end
end
