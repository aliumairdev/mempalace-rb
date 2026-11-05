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

    attr_reader :search_language, :search_query_mode

    SEARCH_LANGUAGE_PATTERN = /\A[a-z][a-z0-9_]{0,62}\z/
    SEARCH_QUERY_MODES = %i[all any].freeze

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
      @search_language = "simple"
      @search_query_mode = :all
    end

    # The PostgreSQL text search configuration used to index drawers and to parse queries ("simple" keeps
    # exact words; "english" adds stemming and stop-word removal). It is interpolated into SQL and into the
    # installed trigger, so it must be a plain configuration name. Changing it after install means
    # re-creating the trigger and re-indexing (see docs/search.md).
    def search_language=(value)
      name = value.to_s
      unless name.match?(SEARCH_LANGUAGE_PATTERN)
        raise ConfigurationError,
              "search_language must be a PostgreSQL text search configuration name (lowercase letters, digits, underscores)"
      end

      @search_language = name
    end

    # :all (the default) keeps websearch_to_tsquery: every word of the query must appear. :any turns the
    # query into its meaningful terms OR-ed together and ranks by how many match, which suits natural-language
    # requests ("write a short direct message" finds "keep every message short and direct").
    def search_query_mode=(value)
      mode = value.to_s.to_sym
      raise ConfigurationError, "search_query_mode must be one of #{SEARCH_QUERY_MODES.join(', ')}" unless SEARCH_QUERY_MODES.include?(mode)

      @search_query_mode = mode
    end

    def single_tenant?
      tenant_mode.to_sym == :single
    end

    def multi_tenant?
      !single_tenant?
    end
  end
end
