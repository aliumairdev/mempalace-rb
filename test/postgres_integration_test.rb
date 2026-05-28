# frozen_string_literal: true

require "test_helper"

class PostgresIntegrationTest < Minitest::Test
  def test_postgres_pgvector_environment_if_configured
    url = ENV.fetch("MEMPALACE_POSTGRES_URL", nil)
    skip "set MEMPALACE_POSTGRES_URL to run PostgreSQL/pgvector integration coverage" if url.blank?

    postgres_model = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
    end
    postgres_model.establish_connection(url)

    version = postgres_model.connection.select_value("SELECT version()")
    assert_includes version.downcase, "postgresql"

    vector_available = postgres_model.connection.select_value("SELECT 1 FROM pg_available_extensions WHERE name = 'vector'")
    skip "pgvector extension is not available in this PostgreSQL instance" if vector_available.blank?

    postgres_model.connection.execute("CREATE EXTENSION IF NOT EXISTS vector")
    assert postgres_model.connection.extension_enabled?("vector")
  ensure
    postgres_model&.connection_pool&.disconnect!
  end
end
