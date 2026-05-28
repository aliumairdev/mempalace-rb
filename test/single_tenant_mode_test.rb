# frozen_string_literal: true

require "test_helper"

class SingleTenantModeTest < MempalaceTest
  def setup
    super
    Mempalace.configure do |config|
      config.tenant_mode = :single
      config.single_tenant_id = 0
    end
  end

  def test_remember_search_context_and_status_without_tenant
    drawer = Mempalace.remember(
      wing: "Personal App",
      room: "architecture",
      content: "Use SQLite first and pgvector later.",
      memory_type: "decision"
    )

    results = Mempalace.search(query: "pgvector later", wing: "Personal App")
    context = Mempalace.context_for(query: "pgvector", wing: "Personal App")
    status = Mempalace.status

    assert_equal 0, drawer.account_id
    assert_equal drawer.id, results.first[:drawer_id]
    assert_includes context, "Use SQLite first"
    assert_equal 1, status[:drawers]
  end

  def test_taxonomy_duplicate_and_exchange_without_tenant
    Mempalace.remember(wing: "Solo", room: "notes", content: "Remember the exact setup.")
    exchange = Mempalace.remember_exchange(wing: "Solo", user: "What setup?", assistant: "SQLite first.")

    duplicate = Mempalace.duplicate?(content: "remember the exact setup")
    wings = Mempalace.list_wings
    rooms = Mempalace.list_rooms(wing: "Solo")
    taxonomy = Mempalace.taxonomy

    assert_includes exchange.content, "Assistant: SQLite first."
    assert duplicate[:duplicate]
    assert_equal ["Solo"], wings.pluck(:name)
    assert_equal %w[conversations notes], rooms.pluck(:slug).sort
    assert_equal 2, taxonomy["Solo"].values.sum
  end

  def test_advanced_layers_without_tenant
    fact = Mempalace.kg.add(subject: "Solo App", predicate: "uses", object: "SQLite")
    tunnel = Mempalace.tunnels.create(
      source_wing: "Solo",
      source_room: "architecture",
      target_wing: "Solo",
      target_room: "database"
    )
    diary = Mempalace.diary.write(agent_name: "agent", entry: "No tenant object needed.")

    assert_equal 0, fact.account_id
    assert_equal tunnel, Mempalace.tunnels.follow(wing: "Solo", room: "database").first
    assert_equal diary, Mempalace.diary.read(agent_name: "agent").first
  end

  def test_find_from_env_returns_single_tenant_id_without_account_model_lookup
    assert_equal 0, Mempalace::Tenant.find_from_env!
  end
end
