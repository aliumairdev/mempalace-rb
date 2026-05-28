# frozen_string_literal: true

module Mempalace
  module Services
    module ResultFormatter
      module_function

      def drawer(drawer, score: 0.0, metadata: nil)
        {
          drawer_id: drawer.id,
          content: drawer.content,
          wing: drawer.wing&.slug,
          room: drawer.room&.slug,
          memory_type: drawer.memory_type,
          score: score.to_f.round(4),
          metadata: metadata || drawer.metadata || {}
        }
      end
    end
  end
end
