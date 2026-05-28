# frozen_string_literal: true

module Mempalace
  module Search
    class HybridSearch
      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(query:, tenant: nil, wing: nil, room: nil, memory_type: nil, source_type: nil, limit: 5, closet_boost: true)
        @tenant = tenant
        @query = query
        @wing = wing
        @room = room
        @memory_type = memory_type
        @source_type = source_type
        @limit = limit.to_i
        @closet_boost = closet_boost
      end

      def call
        keyword = Mempalace.keyword_search(**base_args, limit: @limit * 4)
        semantic = Mempalace.semantic_search(**base_args, limit: @limit * 4)
        closet = @closet_boost ? Mempalace::Closets::Searcher.call(**base_args, limit: @limit * 2) : []
        merge(keyword: keyword, semantic: semantic, closet: closet)
      end

      private

      def base_args
        {
          tenant: @tenant,
          query: @query,
          wing: @wing,
          room: @room,
          memory_type: @memory_type,
          source_type: @source_type
        }
      end

      def merge(keyword:, semantic:, closet:)
        by_id = {}
        keyword.each { |result| merge_score(by_id, result, :keyword) }
        semantic.each { |result| merge_score(by_id, result, :semantic) }
        closet.each { |result| merge_score(by_id, result, :closet) }

        drawer_ids = by_id.keys
        drawers = Mempalace::Drawer.where(id: drawer_ids).includes(:wing, :room).index_by(&:id)

        results = by_id.filter_map do |id, scores|
          drawer = drawers[id]
          next unless drawer

          final = (scores[:semantic].to_f * 0.70) +
                  (scores[:keyword].to_f * 0.25) +
                  (Mempalace::Search::Scorer.recency_score(drawer.filed_at) * 0.05) +
                  (scores[:closet].to_f * 0.10)
          Services::ResultFormatter.drawer(drawer, score: final)
        end

        results.sort_by { |result| -result[:score] }.first(@limit)
      end

      def merge_score(by_id, result, kind)
        id = result[:drawer_id]
        by_id[id] ||= { keyword: 0.0, semantic: 0.0, closet: 0.0 }
        by_id[id][kind] = [by_id[id][kind].to_f, result[:score].to_f].max
      end
    end
  end
end
