# frozen_string_literal: true

require "test_helper"

class RememberTest < MempalaceTest
  def test_remember_creates_wing_room_and_drawer_with_verbatim_content
    tenant = account
    content = "Use pgvector for semantic search.\nKeep this text verbatim."

    drawer = Mempalace.remember(
      tenant: tenant,
      wing: "AI Receptionist",
      room: "architecture",
      content: content,
      memory_type: "decision",
      source_type: "manual"
    )

    assert_equal content, drawer.content
    assert_equal tenant.id, drawer.account_id
    assert_equal "ai-receptionist", drawer.wing.slug
    assert_equal "architecture", drawer.room.slug
    assert_equal "decision", drawer.memory_type
    assert_equal "skipped", drawer.reload.embedding_status
  end

  def test_duplicate_returns_existing_drawer_inside_same_tenant
    tenant = account
    first = Mempalace.remember(tenant: tenant, wing: "A", room: "R", content: "Use pgvector.")
    second = Mempalace.remember(tenant: tenant, wing: "A", room: "R", content: " use   PGVECTOR. ")

    assert_equal first.id, second.id
    assert_equal 1, Mempalace::Drawer.for_tenant(tenant).count
  end

  def test_duplicate_is_scoped_by_tenant
    tenant_a = account("A")
    tenant_b = account("B")

    a = Mempalace.remember(tenant: tenant_a, wing: "A", room: "R", content: "Same memory.")
    b = Mempalace.remember(tenant: tenant_b, wing: "A", room: "R", content: "Same memory.")

    refute_equal a.id, b.id
  end

  def test_missing_tenant_raises
    assert_raises(Mempalace::MissingTenantError) do
      Mempalace.remember(tenant: nil, wing: "A", room: "R", content: "x")
    end
  end

  def test_missing_content_raises
    assert_raises(Mempalace::ValidationError) do
      Mempalace.remember(tenant: account, wing: "A", room: "R", content: "")
    end
  end

  def test_remember_exchange
    drawer = Mempalace.remember_exchange(
      tenant: account,
      wing: "AI Receptionist",
      user: "What stack?",
      assistant: "Rails and pgvector."
    )

    assert_includes drawer.content, "User: What stack?"
    assert_includes drawer.content, "Assistant: Rails and pgvector."
    assert_equal "conversation", drawer.memory_type
  end

  def test_duplicate_check
    tenant = account
    Mempalace.remember(tenant: tenant, wing: "A", room: "R", content: "Remember this exact phrase.")

    result = Mempalace.duplicate?(tenant: tenant, content: "remember this exact phrase")

    assert result[:duplicate]
    assert_equal 1, result[:matches].length
  end
end
