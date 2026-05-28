# frozen_string_literal: true

module Mempalace
  module Search
    class SemanticSearch
      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(query:, tenant: nil, wing: nil, room: nil, memory_type: nil, source_type: nil, limit: 5)
        @tenant = tenant
        @query = query
        @wing = wing
        @room = room
        @memory_type = memory_type
        @source_type = source_type
        @limit = limit.to_i
      end

      def call
        raise ValidationError, "query is required" if @query.blank?

        query_vector = Mempalace::Embedding::ProviderFactory.build.embed(@query)
        return [] if query_vector.blank?

        scope = Filters.drawer_scope(
          tenant: @tenant,
          wing: @wing,
          room: @room,
          memory_type: @memory_type,
          source_type: @source_type
        ).embedded

        ruby_vector_search(scope, query_vector)
      rescue StandardError
        []
      end

      private

      def ruby_vector_search(scope, query_vector)
        scope.to_a
             .map { |drawer| [drawer, Scorer.cosine_similarity(query_vector, drawer.embedding_vector)] }
             .select { |_drawer, score| score.positive? }
             .sort_by { |_drawer, score| -score }
             .first(@limit)
             .map { |drawer, score| Services::ResultFormatter.drawer(drawer, score: score) }
      end
    end
  end
end
