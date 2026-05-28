# frozen_string_literal: true

module Mempalace
  module Embedding
    module ProviderFactory
      module_function

      def build(provider = Mempalace.configuration.embedding_provider)
        return provider if provider.respond_to?(:embed)

        case provider.to_sym
        when :null
          NullProvider.new
        when :ruby_llm
          RubyLlmProvider.new
        when :openai, :open_ai
          OpenAiProvider.new
        when :openrouter, :open_router
          OpenRouterProvider.new
        when :ollama
          OllamaProvider.new
        else
          raise ConfigurationError, "unknown embedding provider: #{provider.inspect}"
        end
      end
    end
  end
end
