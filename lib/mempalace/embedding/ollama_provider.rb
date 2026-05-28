# frozen_string_literal: true

module Mempalace
  module Embedding
    class OllamaProvider < HttpProvider
      def embed(text)
        faraday
        response = Faraday.post("#{Mempalace.configuration.ollama_base_url}/api/embeddings") do |req|
          req.headers["Content-Type"] = "application/json"
          req.options.timeout = Mempalace.configuration.embedding_timeout
          req.body = {
            model: Mempalace.configuration.embedding_model || "nomic-embed-text",
            prompt: text.to_s
          }.to_json
        end
        raise EmbeddingError, "Ollama embedding failed with HTTP #{response.status}" unless response.success?

        parse_embedding_response(response)
      end
    end
  end
end
