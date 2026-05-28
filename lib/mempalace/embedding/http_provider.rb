# frozen_string_literal: true

require "json"

module Mempalace
  module Embedding
    class HttpProvider < BaseProvider
      private

      def faraday
        require "faraday"
      rescue LoadError => e
        raise ConfigurationError, "faraday is required for #{self.class.name}: #{e.message}"
      end

      def parse_embedding_response(response)
        body = JSON.parse(response.body)
        vector = body.dig("data", 0, "embedding") || body["embedding"]
        raise EmbeddingError, "embedding response did not include a vector" unless vector.is_a?(Array)

        vector.map(&:to_f)
      rescue JSON::ParserError => e
        raise EmbeddingError, "embedding response was not valid JSON: #{e.message}"
      end
    end
  end
end
