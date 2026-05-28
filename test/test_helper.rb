# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "bundler/setup"
require "minitest/autorun"
require "active_record"
require "active_job"
require "logger"
require "tmpdir"

require "mempalace"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(nil)
ActiveJob::Base.queue_adapter = :inline

class Account < ActiveRecord::Base
end

ActiveRecord::Schema.define do
  create_table :accounts, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :mempalace_wings, force: true do |t|
    t.bigint :account_id, null: false
    t.string :name, null: false
    t.string :slug, null: false
    t.json :metadata, null: false, default: {}
    t.timestamps
  end
  add_index :mempalace_wings, %i[account_id slug], unique: true

  create_table :mempalace_rooms, force: true do |t|
    t.bigint :account_id, null: false
    t.references :wing, null: false
    t.string :name, null: false
    t.string :slug, null: false
    t.json :metadata, null: false, default: {}
    t.timestamps
  end
  add_index :mempalace_rooms, %i[account_id wing_id slug], unique: true

  create_table :mempalace_drawers, force: true do |t|
    t.bigint :account_id, null: false
    t.references :wing, null: false
    t.references :room, null: false
    t.text :content, null: false
    t.string :content_sha256, null: false
    t.string :normalized_content_sha256, null: false
    t.string :memory_type, null: false, default: "general"
    t.string :source_type
    t.string :source_id
    t.string :source_file
    t.integer :chunk_index, null: false, default: 0
    t.integer :line_start
    t.integer :line_end
    t.datetime :filed_at, null: false
    t.json :metadata, null: false, default: {}
    t.text :embedding
    t.string :embedding_model
    t.string :embedding_status, null: false, default: "pending"
    t.text :embedding_error
    t.datetime :embedded_at
    t.timestamps
  end
  add_index :mempalace_drawers, %i[account_id content_sha256], unique: true
  add_index :mempalace_drawers, %i[account_id normalized_content_sha256]

  create_table :mempalace_closets, force: true do |t|
    t.bigint :account_id, null: false
    t.references :wing, null: false
    t.references :room, null: false
    t.text :pointer_text, null: false
    t.json :drawer_ids, null: false, default: []
    t.json :entities, null: false, default: []
    t.json :topics, null: false, default: []
    t.string :source_file
    t.json :metadata, null: false, default: {}
    t.text :embedding
    t.string :embedding_model
    t.string :embedding_status, null: false, default: "pending"
    t.timestamps
  end

  create_table :mempalace_facts, force: true do |t|
    t.bigint :account_id, null: false
    t.string :subject, null: false
    t.string :predicate, null: false
    t.string :object, null: false
    t.datetime :valid_from
    t.datetime :valid_to
    t.float :confidence, null: false, default: 1.0
    t.references :source_drawer
    t.json :metadata, null: false, default: {}
    t.timestamps
  end

  create_table :mempalace_tunnels, force: true do |t|
    t.bigint :account_id, null: false
    t.references :source_wing, null: false
    t.references :source_room, null: false
    t.references :target_wing, null: false
    t.references :target_room, null: false
    t.string :kind, null: false, default: "explicit"
    t.string :label
    t.float :strength, null: false, default: 1.0
    t.json :metadata, null: false, default: {}
    t.timestamps
  end

  create_table :mempalace_diary_entries, force: true do |t|
    t.bigint :account_id, null: false
    t.references :wing
    t.string :agent_name, null: false
    t.string :topic, null: false, default: "general"
    t.text :entry, null: false
    t.datetime :written_at, null: false
    t.json :metadata, null: false, default: {}
    t.timestamps
  end
end

class MempalaceTest < Minitest::Test
  def setup
    Mempalace.reset_configuration!
    Mempalace.configure do |config|
      config.embedding_provider = :null
      config.null_provider_mode = :none
      config.auto_embed = true
      config.tenant_model = "Account"
      config.tenant_foreign_key = :account_id
    end
    [Mempalace::DiaryEntry, Mempalace::Tunnel, Mempalace::Fact, Mempalace::Closet,
     Mempalace::Drawer, Mempalace::Room, Mempalace::Wing, Account].each(&:delete_all)
  end

  def account(name = "Acme")
    Account.create!(name: name)
  end
end
