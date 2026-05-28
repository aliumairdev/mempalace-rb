# frozen_string_literal: true

module Mempalace
  module Closets
    class Builder
      MAX_POINTER_CHARS = 1_500

      def self.call(drawers:)
        new(drawers: drawers).call
      end

      def initialize(drawers:)
        @drawers = Array(drawers).compact
      end

      def call
        return [] if @drawers.empty?

        grouped = @drawers.group_by { |drawer| [drawer.tenant_id, drawer.wing_id, drawer.room_id, drawer.source_file] }
        grouped.flat_map { |_key, drawers| build_for_group(drawers) }
      end

      private

      def build_for_group(drawers)
        first = drawers.first
        topics = extract_topics(drawers.map(&:content).join("\n"))
        entities = extract_entities(drawers.map(&:content).join("\n"))
        lines = topics.presence || ["#{first.wing.slug}/#{first.room.slug}/#{File.basename(first.source_file.to_s.presence || 'memory')}"]
        pointer_lines = lines.map do |topic|
          "#{topic}|#{entities.join(';')}|->#{drawers.map(&:id).join(',')}"
        end

        pointer_lines.each_slice(20).map.with_index do |slice, index|
          text = slice.join("\n")[0, MAX_POINTER_CHARS]
          Mempalace::Closet.create!(
            Mempalace::Tenant.foreign_key => first.tenant_id,
            wing: first.wing,
            room: first.room,
            pointer_text: text,
            drawer_ids: drawers.map(&:id),
            entities: entities,
            topics: topics,
            source_file: first.source_file,
            metadata: { closet_index: index }
          )
        end
      end

      def extract_topics(text)
        topics = []
        text.scan(/^\#{1,3}\s+(.{3,80})$/) { |match| topics << match.first.strip }
        text.scan(/\b(?:built|fixed|added|decided|migrated|configured|implemented|use|choose)\s+[^.]{3,80}/i) do |match|
          topics << match.strip
        end
        topics.map { |topic| topic.gsub(/\s+/, " ").downcase }.uniq.first(12)
      end

      def extract_entities(text)
        text.scan(/\b[A-Z][A-Za-z0-9_-]{2,}\b/)
            .tally
            .select { |_word, count| count >= 2 }
            .keys
            .first(8)
      end
    end
  end
end
