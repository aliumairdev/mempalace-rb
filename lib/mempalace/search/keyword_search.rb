# frozen_string_literal: true

module Mempalace
  module Search
    class KeywordSearch
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

        scope = Filters.drawer_scope(
          tenant: @tenant,
          wing: @wing,
          room: @room,
          memory_type: @memory_type,
          source_type: @source_type
        )

        if Capabilities.postgresql? && Capabilities.search_vector?
          postgres_search(scope)
        else
          fallback_search(scope)
        end
      end

      # The tsquery for this search, as SQL. language and mode come from configuration (the language is
      # validated to a plain name); the query text is always a bound or quoted value.
      def self.tsquery_sql(language:, mode:, quoted_query:)
        case mode.to_sym
        when :any then "replace(plainto_tsquery('#{language}', #{quoted_query})::text, ' & ', ' | ')::tsquery"
        else "websearch_to_tsquery('#{language}', #{quoted_query})"
        end
      end

      private

      def postgres_search(scope)
        config = Mempalace.configuration
        tsquery = self.class.tsquery_sql(language: config.search_language, mode: config.search_query_mode, quoted_query: ActiveRecord::Base.connection.quote(@query))
        rank_sql = "ts_rank_cd(search_vector, #{tsquery})"
        rows = scope
               .select("mempalace_drawers.*, #{rank_sql} AS mempalace_rank")
               .where("search_vector @@ #{tsquery}")
               .order("mempalace_rank DESC, mempalace_drawers.filed_at DESC")
               .limit(@limit)

        rows.map do |drawer|
          score = drawer.respond_to?(:mempalace_rank) ? drawer.mempalace_rank.to_f : Scorer.keyword_score(@query, drawer.content)
          Services::ResultFormatter.drawer(drawer, score: score)
        end
      rescue ActiveRecord::StatementInvalid
        fallback_search(scope)
      end

      def fallback_search(scope)
        terms = Scorer.tokenize(@query)
        return [] if terms.empty?

        scope.to_a
             .map { |drawer| [drawer, Scorer.keyword_score(@query, drawer.content)] }
             .select { |_drawer, score| score.positive? }
             .sort_by { |drawer, score| [-score, -drawer.filed_at.to_i] }
             .first(@limit)
             .map { |drawer, score| Services::ResultFormatter.drawer(drawer, score: score) }
      end
    end
  end
end
