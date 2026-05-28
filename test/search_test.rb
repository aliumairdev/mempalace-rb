# frozen_string_literal: true

require "test_helper"

class SearchTest < MempalaceTest
  def test_keyword_search_and_hybrid_result_format
    tenant = account
    Mempalace.remember(tenant: tenant, wing: "AI Receptionist", room: "architecture",
                       content: "Use Rails 8.1 and pgvector for semantic search.", memory_type: "decision")
    Mempalace.remember(tenant: tenant, wing: "AI Receptionist", room: "billing", content: "Stripe invoices are synced nightly.",
                       memory_type: "fact")

    results = Mempalace.search(tenant: tenant, query: "pgvector semantic stack", wing: "AI Receptionist", limit: 5)

    assert_equal 1, results.length
    assert_equal "architecture", results.first[:room]
    assert_includes results.first[:content], "pgvector"
    assert_predicate results.first[:score], :positive?
  end

  def test_search_filters_room_memory_type_and_source_type
    tenant = account
    Mempalace.remember(tenant: tenant, wing: "W", room: "architecture", content: "Use OpenRouter embeddings.", memory_type: "decision",
                       source_type: "manual")
    Mempalace.remember(tenant: tenant, wing: "W", room: "notes", content: "OpenRouter appears in notes.", memory_type: "general",
                       source_type: "project")

    results = Mempalace.search(tenant: tenant, query: "OpenRouter", room: "architecture", memory_type: "decision", source_type: "manual")

    assert_equal 1, results.length
    assert_equal "architecture", results.first[:room]
  end

  def test_cross_tenant_isolation
    tenant_a = account("A")
    tenant_b = account("B")
    Mempalace.remember(tenant: tenant_a, wing: "W", room: "R", content: "Tenant A secret stack.")
    Mempalace.remember(tenant: tenant_b, wing: "W", room: "R", content: "Tenant B appointment safety.")

    results = Mempalace.search(tenant: tenant_a, query: "appointment safety")

    assert_empty results
  end

  def test_semantic_search_gracefully_degrades_without_vectors
    tenant = account
    Mempalace.remember(tenant: tenant, wing: "W", room: "R", content: "Use pgvector.")

    assert_equal [], Mempalace.semantic_search(tenant: tenant, query: "pgvector")
  end

  def test_semantic_search_with_deterministic_null_provider
    Mempalace.configure do |config|
      config.null_provider_mode = :deterministic
      config.embedding_model = "test-null"
    end
    tenant = account
    drawer = Mempalace.remember(tenant: tenant, wing: "W", room: "R", content: "Alpha beta gamma memory.")

    assert_equal "embedded", drawer.reload.embedding_status

    results = Mempalace.semantic_search(tenant: tenant, query: "Alpha beta")
    assert_equal drawer.id, results.first[:drawer_id]
  end

  def test_context_for_and_wake_up
    tenant = account
    Mempalace.remember(tenant: tenant, wing: "AI Receptionist", room: "architecture", content: "Use Rails and pgvector.",
                       memory_type: "decision")

    context = Mempalace.context_for(tenant: tenant, query: "pgvector", wing: "AI Receptionist", max_tokens: 100)
    wake = Mempalace.wake_up(tenant: tenant, wing: "AI Receptionist")

    assert_includes context, "Relevant memory:"
    assert_includes context, "Use Rails and pgvector."
    assert_includes wake, "L1: critical decisions/facts"
  end
end
