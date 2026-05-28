# frozen_string_literal: true

module Mempalace
  module Embedding
    class RubyLlmProvider < BaseProvider
      def embed(text)
        begin
          require "ruby_llm"
        rescue LoadError => e
          raise ConfigurationError, "ruby_llm is required for RubyLlmProvider: #{e.message}"
        end

        if RubyLLM.respond_to?(:embed)
          result = RubyLLM.embed(text.to_s, model: Mempalace.configuration.embedding_model)
          return extract_vector(result)
        end

        if defined?(RubyLLM::Embedding) && RubyLLM::Embedding.respond_to?(:create)
          result = RubyLLM::Embedding.create(input: text.to_s, model: Mempalace.configuration.embedding_model)
          return extract_vector(result)
        end

        raise ConfigurationError, "installed ruby_llm version does not expose a known embedding API"
      end

      private

      def extract_vector(result)
        vector =
          if result.is_a?(Array)
            result
          elsif result.respond_to?(:embedding)
            result.embedding
          elsif result.respond_to?(:vector)
            result.vector
          elsif result.respond_to?(:to_h)
            hash = result.to_h
            hash[:embedding] || hash["embedding"] || hash.dig(:data, 0, :embedding) || hash.dig("data", 0, "embedding")
          end
        raise EmbeddingError, "ruby_llm embedding result did not include a vector" unless vector.is_a?(Array)

        vector.map(&:to_f)
      end
    end
  end
end
