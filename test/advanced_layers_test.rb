# frozen_string_literal: true

require "test_helper"

class AdvancedLayersTest < MempalaceTest
  def test_fact_store_add_query_invalidate_and_timeline
    tenant = account
    fact = Mempalace.kg.add(tenant: tenant, subject: "AI Receptionist", predicate: "uses", object: "pgvector")

    assert_equal [fact], Mempalace.kg.query(tenant: tenant, entity: "AI Receptionist")

    Mempalace.kg.invalidate(tenant: tenant, subject: "AI Receptionist", predicate: "uses", object: "pgvector", ended: 1.day.ago)
    assert_empty Mempalace.kg.query(tenant: tenant, entity: "AI Receptionist")
    assert_equal 1, Mempalace.kg.timeline(tenant: tenant, entity: "AI Receptionist").length
  end

  def test_tunnels_create_list_follow
    tenant = account
    tunnel = Mempalace.tunnels.create(
      tenant: tenant,
      source_wing: "Project A",
      source_room: "architecture",
      target_wing: "Project B",
      target_room: "database",
      label: "shared pgvector design"
    )

    assert_equal "shared pgvector design", tunnel.label
    assert_equal [tunnel], Mempalace.tunnels.list(tenant: tenant, wing: "Project A")
    assert_equal [tunnel], Mempalace.tunnels.follow(tenant: tenant, wing: "Project A", room: "architecture")
  end

  def test_diary_write_and_read
    tenant = account
    entry = Mempalace.diary.write(tenant: tenant, agent_name: "Claude", entry: "Remembered install flow.", topic: "setup")

    assert_equal "claude", entry.agent_name
    assert_equal [entry], Mempalace.diary.read(tenant: tenant, agent_name: "claude")
  end

  def test_advanced_layers_are_tenant_scoped
    tenant_a = account("A")
    tenant_b = account("B")
    Mempalace.kg.add(tenant: tenant_a, subject: "Secret", predicate: "belongs_to", object: "A")

    assert_empty Mempalace.kg.query(tenant: tenant_b, entity: "Secret")
  end
end
