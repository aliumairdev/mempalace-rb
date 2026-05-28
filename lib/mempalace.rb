# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"
require "active_record"
require "active_job"

require "mempalace/version"
require "mempalace/errors"
require "mempalace/configuration"
require "mempalace/slugger"
require "mempalace/hashing"
require "mempalace/tenant"

module Mempalace
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
      configuration
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def tenant_id_for(tenant)
      Tenant.id_for(tenant)
    end

    def remember(**kwargs)
      Services::Remember.call(**kwargs)
    end

    def remember_exchange(**kwargs)
      Services::RememberExchange.call(**kwargs)
    end

    def duplicate?(**kwargs)
      Services::DuplicateCheck.call(**kwargs)
    end

    def keyword_search(**kwargs)
      Search::KeywordSearch.call(**kwargs)
    end

    def semantic_search(**kwargs)
      Search::SemanticSearch.call(**kwargs)
    end

    def search(**kwargs)
      Search::HybridSearch.call(**kwargs)
    end

    def context_for(**kwargs)
      Services::ContextBuilder.call(**kwargs)
    end

    def wake_up(**kwargs)
      Services::WakeUp.call(**kwargs)
    end

    def mine_project(**kwargs)
      Miners::ProjectMiner.call(**kwargs)
    end

    def mine_conversation(**kwargs)
      Miners::ConversationMiner.call(**kwargs)
    end

    def status(**kwargs)
      Services::Status.call(**kwargs)
    end

    def list_wings(**kwargs)
      Services::Taxonomy.list_wings(**kwargs)
    end

    def list_rooms(**kwargs)
      Services::Taxonomy.list_rooms(**kwargs)
    end

    def taxonomy(**kwargs)
      Services::Taxonomy.call(**kwargs)
    end

    def kg
      KnowledgeGraph::FactStore
    end

    def diary
      Diary::Store
    end

    def tunnels
      Tunnels::Store
    end
  end
end

require "mempalace/engine" if defined?(Rails::Engine)

require_relative "../app/models/mempalace/application_record"
require_relative "../app/models/mempalace/wing"
require_relative "../app/models/mempalace/room"
require_relative "../app/models/mempalace/drawer"
require_relative "../app/models/mempalace/closet"
require_relative "../app/models/mempalace/fact"
require_relative "../app/models/mempalace/tunnel"
require_relative "../app/models/mempalace/diary_entry"

require "mempalace/embedding/base_provider"
require "mempalace/embedding/null_provider"
require "mempalace/embedding/http_provider"
require "mempalace/embedding/open_ai_provider"
require "mempalace/embedding/open_router_provider"
require "mempalace/embedding/ollama_provider"
require "mempalace/embedding/ruby_llm_provider"
require "mempalace/embedding/provider_factory"

require_relative "../app/jobs/mempalace/embed_drawer_job"
require_relative "../app/jobs/mempalace/reindex_drawer_job"
require_relative "../app/jobs/mempalace/mine_project_job"
require_relative "../app/jobs/mempalace/mine_conversation_job"

require "mempalace/services/remember"
require "mempalace/services/remember_exchange"
require "mempalace/services/duplicate_check"
require "mempalace/services/result_formatter"
require "mempalace/services/context_builder"
require "mempalace/services/wake_up"
require "mempalace/services/status"
require "mempalace/services/taxonomy"

require "mempalace/search/capabilities"
require "mempalace/search/filters"
require "mempalace/search/scorer"
require "mempalace/search/keyword_search"
require "mempalace/search/semantic_search"
require "mempalace/search/hybrid_search"

require "mempalace/chunking/paragraph_chunker"
require "mempalace/chunking/conversation_chunker"
require "mempalace/detection/room_detector"
require "mempalace/detection/memory_type_detector"
require "mempalace/miners/file_scanner"
require "mempalace/miners/project_miner"
require "mempalace/miners/conversation_miner"
require "mempalace/closets/builder"
require "mempalace/closets/searcher"
require "mempalace/knowledge_graph/fact_store"
require "mempalace/diary/store"
require "mempalace/tunnels/store"
