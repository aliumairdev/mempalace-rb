# frozen_string_literal: true

module Mempalace
  module Services
    class ContextBuilder
      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(query:, tenant: nil, wing: nil, room: nil, memory_type: nil, source_type: nil, limit: 10, max_tokens: 2_000)
        @tenant = tenant
        @query = query
        @wing = wing
        @room = room
        @memory_type = memory_type
        @source_type = source_type
        @limit = limit
        @max_tokens = max_tokens
      end

      def call
        results = Mempalace.search(
          tenant: @tenant,
          query: @query,
          wing: @wing,
          room: @room,
          memory_type: @memory_type,
          source_type: @source_type,
          limit: @limit
        )

        return "Relevant memory:\n\nNo matching memories found." if results.empty?

        budget_chars = [@max_tokens.to_i * 4, 200].max
        lines = ["Relevant memory:", ""]
        results.each do |result|
          block = "[#{result[:wing]} / #{result[:room]} / #{result[:memory_type]}]\n"
          block << result[:content].to_s.strip
          block << "\n"
          break if (lines.join("\n").length + block.length) > budget_chars

          lines << block
        end
        lines.join("\n").strip
      end
    end
  end
end
