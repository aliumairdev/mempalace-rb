# frozen_string_literal: true

Mempalace.configure do |config|
  config.embedding_provider = :null
  config.embedding_model = nil
  config.vector_dimensions = 1536

  config.tenant_model = "Account"
  config.tenant_foreign_key = :account_id
  config.tenant_mode = :multi
  config.single_tenant_id = 0

  # For a simple non-multitenant app, use:
  # config.tenant_mode = :single
  #
  # Then calls like Mempalace.remember(wing:, room:, content:) work without tenant:.

  config.default_chunk_size = 800
  config.default_chunk_overlap = 100

  config.auto_embed = true
  config.embedding_queue = :default

  config.allowed_file_extensions = %w[
    .rb .md .txt .yml .yaml .json .js .ts .tsx .jsx .sql .sh .erb .haml .slim
  ]

  config.excluded_directories = %w[
    .git node_modules tmp log storage vendor/bundle .next dist build coverage
  ]
end
