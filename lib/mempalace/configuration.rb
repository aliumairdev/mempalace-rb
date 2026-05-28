# frozen_string_literal: true

module Mempalace
  class Configuration
    DEFAULT_EXTENSIONS = %w[
      .rb .md .txt .yml .yaml .json .js .ts .tsx .jsx .sql .sh .erb .haml .slim
    ].freeze

    DEFAULT_EXCLUDED_DIRECTORIES = %w[
      .git node_modules tmp log storage vendor/bundle .next dist build coverage
    ].freeze

    attr_accessor :embedding_provider,
                  :embedding_model,
                  :vector_dimensions,
                  :tenant_model,
                  :tenant_foreign_key,
                  :tenant_mode,
                  :single_tenant_id,
                  :tenant_resolver,
                  :default_chunk_size,
                  :default_chunk_overlap,
                  :min_chunk_size,
                  :auto_embed,
                  :embedding_queue,
                  :allowed_file_extensions,
                  :excluded_directories,
                  :max_file_size,
                  :null_provider_mode,
                  :embedding_timeout,
                  :embedding_retries,
                  :openai_api_key,
                  :openai_base_url,
                  :openrouter_api_key,
                  :openrouter_base_url,
                  :ollama_base_url,
                  :log_content

    def initialize
      @embedding_provider = :null
      @embedding_model = nil
      @vector_dimensions = 1536
      @tenant_model = "Account"
      @tenant_foreign_key = :account_id
      @tenant_mode = :multi
      @single_tenant_id = 0
      @tenant_resolver = nil
      @default_chunk_size = 800
      @default_chunk_overlap = 100
      @min_chunk_size = 20
      @auto_embed = true
      @embedding_queue = :default
      @allowed_file_extensions = DEFAULT_EXTENSIONS.dup
      @excluded_directories = DEFAULT_EXCLUDED_DIRECTORIES.dup
      @max_file_size = 5 * 1024 * 1024
      @null_provider_mode = :none
      @embedding_timeout = 30
      @embedding_retries = 3
      @openai_api_key = nil
      @openai_base_url = "https://api.openai.com/v1"
      @openrouter_api_key = nil
      @openrouter_base_url = "https://openrouter.ai/api/v1"
      @ollama_base_url = "http://localhost:11434"
      @log_content = false
    end

    def single_tenant?
      tenant_mode.to_sym == :single
    end

    def multi_tenant?
      !single_tenant?
    end
  end
end
