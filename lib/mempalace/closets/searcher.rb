# frozen_string_literal: true

module Mempalace
  module Closets
    class Searcher
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
        tenant_id = Mempalace.tenant_id_for(@tenant)
        scope = Mempalace::Closet.where(Mempalace::Tenant.foreign_key => tenant_id).includes(:wing, :room)
        scope = scope.in_wing(@wing) if @wing.present?
        scope = scope.in_room(@room) if @room.present?

        candidates = scope.to_a
                          .map { |closet| [closet, Mempalace::Search::Scorer.keyword_score(@query, closet.pointer_text)] }
                          .select { |_closet, score| score.positive? }
                          .sort_by { |_closet, score| -score }
                          .first(@limit)

        drawer_ids = candidates.flat_map { |closet, _score| Array(closet.drawer_ids) }.uniq
        drawers = Mempalace::Drawer.filtered(
          tenant: @tenant,
          wing: @wing,
          room: @room,
          memory_type: @memory_type,
          source_type: @source_type
        ).where(id: drawer_ids).includes(:wing, :room).index_by(&:id)

        results = candidates.flat_map do |closet, score|
          Array(closet.drawer_ids).filter_map do |drawer_id|
            drawer = drawers[drawer_id.to_i] || drawers[drawer_id.to_s]
            next unless drawer

            Services::ResultFormatter.drawer(drawer, score: score * 0.5, metadata: drawer.metadata.merge(matched_via: "closet"))
          end
        end

        results.uniq { |result| result[:drawer_id] }.first(@limit)
      end
    end
  end
end
