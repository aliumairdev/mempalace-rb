# frozen_string_literal: true

require "pathname"

module Mempalace
  module Miners
    class ProjectMiner
      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(path:, tenant: nil, wing: nil, async: false, rooms: nil, limit: nil)
        @tenant = tenant
        @path = Pathname(path).expand_path
        @wing = wing
        @async = async
        @rooms = rooms
        @limit = limit
      end

      def call
        if @async
          job = Mempalace::MineProjectJob.perform_later(tenant_id: Mempalace.tenant_id_for(@tenant), path: @path.to_s, wing: @wing,
                                                        options: { rooms: @rooms, limit: @limit }.compact)
          return { job_id: job.job_id }
        end

        files = Mempalace::Miners::FileScanner.call(path: @path)
        files = files.first(@limit.to_i) if @limit.present?
        total = 0
        files.each do |file|
          content = file.read
          room = Mempalace::Detection::RoomDetector.call(path: file.relative_path_from(@path), content: content, rooms: @rooms)
          chunks = Mempalace::Chunking::ParagraphChunker.call(content, source_file: file.to_s)
          chunks.each do |chunk|
            Mempalace.remember(
              tenant: @tenant,
              wing: @wing.presence || @path.basename.to_s,
              room: room,
              content: chunk[:content],
              memory_type: Mempalace::Detection::MemoryTypeDetector.call(chunk[:content]),
              source_type: "project",
              source_id: file.to_s,
              source_file: file.to_s,
              chunk_index: chunk[:chunk_index],
              line_start: chunk[:line_start],
              line_end: chunk[:line_end],
              metadata: { mined_from: "project" },
              build_closet: true
            )
            total += 1
          end
        end
        { files: files.length, drawers: total }
      end
    end
  end
end
