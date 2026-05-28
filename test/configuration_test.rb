# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < MempalaceTest
  def test_defaults
    config = Mempalace.configuration

    assert_equal :null, config.embedding_provider
    assert_equal 1536, config.vector_dimensions
    assert_equal "Account", config.tenant_model
    assert_equal :account_id, config.tenant_foreign_key
    assert_equal :multi, config.tenant_mode
    assert_equal 0, config.single_tenant_id
    assert_includes config.allowed_file_extensions, ".rb"
    assert_includes config.excluded_directories, "node_modules"
  end

  def test_configure_and_reset
    Mempalace.configure do |config|
      config.embedding_provider = :ollama
      config.default_chunk_size = 400
    end

    assert_equal :ollama, Mempalace.configuration.embedding_provider
    assert_equal 400, Mempalace.configuration.default_chunk_size

    Mempalace.reset_configuration!
    assert_equal :null, Mempalace.configuration.embedding_provider
  end
end
