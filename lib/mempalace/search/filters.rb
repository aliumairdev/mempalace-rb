# frozen_string_literal: true

module Mempalace
  module Search
    module Filters
      module_function

      def drawer_scope(tenant: nil, wing: nil, room: nil, memory_type: nil, source_type: nil)
        Mempalace::Drawer.filtered(
          tenant: tenant,
          wing: wing,
          room: room,
          memory_type: memory_type,
          source_type: source_type
        ).includes(:wing, :room)
      end
    end
  end
end
