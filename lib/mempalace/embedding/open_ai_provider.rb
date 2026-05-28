# frozen_string_literal: true

module Mempalace
  module Embedding
    class OpenAiProvider < HttpProvider
      def embed(text)
        faraday
        api_key = Mempalace.configuration.openai_api_key || ENV.fetch("OPENAI_API_KEY", nil)
        raise ConfigurationError, "OPENAI_API_KEY is required for OpenAiProvider" if api_key.blank?

        response = Faraday.post("#{Mempalace.configuration.openai_base_url}/embeddings") do |req|
          req.headers["Authorization"] = "Bearer #{api_key}"
          req.headers["Content-Type"] = "application/json"
          req.options.timeout = Mempalace.configuration.embedding_timeout
          req.body = {
            model: Mempalace.configuration.embedding_model || "text-embedding-3-small",
            input: text.to_s
          }.to_json
        end
        raise EmbeddingError, "OpenAI embedding failed with HTTP #{response.status}" unless response.success?

        parse_embedding_response(response)
      end
    end
  end
end
