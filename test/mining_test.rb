# frozen_string_literal: true

require "test_helper"
require "fileutils"

class MiningTest < MempalaceTest
  def test_project_miner_scans_chunks_and_preserves_source_metadata
    tenant = account
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "README.md"), "# Architecture\n\nUse Rails, pgvector, and Sidekiq for memory.")
      FileUtils.mkdir_p(File.join(dir, "node_modules"))
      File.write(File.join(dir, "node_modules", "skip.md"), "Do not mine")

      result = Mempalace.mine_project(tenant: tenant, path: dir, wing: "Demo")

      assert_equal 1, result[:files]
      assert_equal 1, result[:drawers]
      drawer = Mempalace::Drawer.for_tenant(tenant).first
      assert_equal "project", drawer.source_type
      assert_equal "architecture", drawer.room.slug
      assert_equal 1, Mempalace::Closet.for_tenant(tenant).count
    end
  end

  def test_conversation_miner_groups_user_and_assistant
    tenant = account
    messages = [
      { id: 1, role: "user", content: "What stack?", created_at: Time.current },
      { id: 2, role: "assistant", content: "Rails and pgvector.", created_at: Time.current }
    ]

    result = Mempalace.mine_conversation(tenant: tenant, wing: "Agent", messages: messages)

    assert_equal 1, result[:drawers]
    assert_includes Mempalace::Drawer.first.content, "User: What stack?"
    assert_includes Mempalace::Drawer.first.content, "Assistant: Rails and pgvector."
  end
end
