# frozen_string_literal: true

module Mempalace
  module Embedding
    class OpenRouterProvider < HttpProvider
      def embed(text)
        faraday
        api_key = Mempalace.configuration.openrouter_api_key || ENV.fetch("OPENROUTER_API_KEY", nil)
        raise ConfigurationError, "OPENROUTER_API_KEY is required for OpenRouterProvider" if api_key.blank?

        response = Faraday.post("#{Mempalace.configuration.openrouter_base_url}/embeddings") do |req|
          req.headers["Authorization"] = "Bearer #{api_key}"
          req.headers["Content-Type"] = "application/json"
          req.options.timeout = Mempalace.configuration.embedding_timeout
          req.body = {
            model: Mempalace.configuration.embedding_model || "text-embedding-3-small",
            input: text.to_s
          }.to_json
        end
        raise EmbeddingError, "OpenRouter embedding failed with HTTP #{response.status}" unless response.success?

        parse_embedding_response(response)
      end
    end
  end
end
