# frozen_string_literal: true

require "test_helper"

class EmbeddingTest < MempalaceTest
  def test_provider_selection
    assert_instance_of Mempalace::Embedding::NullProvider, Mempalace::Embedding::ProviderFactory.build(:null)

    assert_raises(Mempalace::ConfigurationError) do
      Mempalace::Embedding::ProviderFactory.build(:missing)
    end
  end

  def test_embedding_failure_keeps_drawer_and_records_error
    provider = Object.new
    def provider.embed(_text)
      raise "provider unavailable"
    end

    Mempalace.configure do |config|
      config.embedding_provider = provider
      config.embedding_model = "test-provider"
    end

    drawer = Mempalace.remember(tenant: account, wing: "W", room: "R", content: "Keep this even if embedding fails.")

    assert_predicate drawer, :persisted?
    assert_equal "failed", drawer.reload.embedding_status
    assert_includes drawer.embedding_error, "provider unavailable"
  end

  def test_reindex_drawer_job_retries_failed_embedding
    failing_provider = Object.new
    def failing_provider.embed(_text)
      raise "temporary failure"
    end

    Mempalace.configure do |config|
      config.embedding_provider = failing_provider
      config.embedding_model = "test-provider"
    end

    drawer = Mempalace.remember(tenant: account, wing: "W", room: "R", content: "Retry embedding later.")
    assert_equal "failed", drawer.reload.embedding_status

    success_provider = Object.new
    def success_provider.embed(_text)
      [1.0, 0.0]
    end

    Mempalace.configure do |config|
      config.embedding_provider = success_provider
      config.embedding_model = "test-provider"
    end

    Mempalace::ReindexDrawerJob.perform_now(drawer.id)

    assert_equal "embedded", drawer.reload.embedding_status
    assert_equal [1.0, 0.0], drawer.embedding_vector
  end
end
