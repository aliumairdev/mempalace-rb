# frozen_string_literal: true

module Mempalace
  module Chunking
    class ParagraphChunker
      def self.call(content, source_file: nil, chunk_size: Mempalace.configuration.default_chunk_size,
                    overlap: Mempalace.configuration.default_chunk_overlap, min_chunk_size: Mempalace.configuration.min_chunk_size)
        new(content, source_file: source_file, chunk_size: chunk_size, overlap: overlap, min_chunk_size: min_chunk_size).call
      end

      def initialize(content, chunk_size:, overlap:, min_chunk_size:, source_file: nil)
        @content = content.to_s.strip
        @source_file = source_file
        @chunk_size = chunk_size.to_i
        @overlap = overlap.to_i
        @min_chunk_size = min_chunk_size.to_i
      end

      def call
        return [] if @content.blank?
        raise ValidationError, "chunk_size must be positive" if @chunk_size <= 0
        raise ValidationError, "chunk_overlap must be smaller than chunk_size" if @overlap >= @chunk_size

        chunks = []
        start = 0
        while start < @content.length
          finish = [start + @chunk_size, @content.length].min
          finish = boundary(start, finish) if finish < @content.length
          text = @content[start...finish].to_s.strip
          if text.length >= @min_chunk_size
            chunks << {
              content: text,
              chunk_index: chunks.length,
              line_start: @content[0...start].to_s.count("\n") + 1,
              line_end: @content[0...finish].to_s.count("\n") + 1,
              source_file: @source_file
            }
          end
          break if finish >= @content.length

          start = [finish - @overlap, start + 1].max
        end
        chunks
      end

      private

      def boundary(start, finish)
        paragraph = @content.rindex("\n\n", finish)
        return paragraph if paragraph && paragraph > start + (@chunk_size / 2)

        line = @content.rindex("\n", finish)
        return line if line && line > start + (@chunk_size / 2)

        finish
      end
    end
  end
end
