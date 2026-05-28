# frozen_string_literal: true

module Mempalace
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class MissingTenantError < Error; end
  class TenantMismatchError < Error; end
  class ValidationError < Error; end
  class EmbeddingError < Error; end
  class SearchError < Error; end
  class MiningError < Error; end
  class NotFoundError < Error; end
end
