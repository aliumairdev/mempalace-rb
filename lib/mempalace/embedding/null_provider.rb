# frozen_string_literal: true

require "digest"

module Mempalace
  module Embedding
    class NullProvider < BaseProvider
      def embed(text)
        return nil unless Mempalace.configuration.null_provider_mode.to_sym == :deterministic

        dimensions = Mempalace.configuration.vector_dimensions.to_i
        vector = Array.new(dimensions, 0.0)
        tokens = text.to_s.downcase.scan(/[[:alnum:]_]{2,}/)
        return vector if tokens.empty?

        tokens.each do |token|
          digest = Digest::SHA256.hexdigest(token)
          vector[digest.to_i(16) % dimensions] += 1.0
        end

        norm = Math.sqrt(vector.sum { |value| value * value })
        return vector if norm.zero?

        vector.map { |value| value / norm }
      end
    end
  end
end
