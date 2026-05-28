# frozen_string_literal: true

require "find"
require "pathname"

module Mempalace
  module Miners
    class FileScanner
      def self.call(path:, allowed_extensions: Mempalace.configuration.allowed_file_extensions,
                    excluded_directories: Mempalace.configuration.excluded_directories,
                    max_file_size: Mempalace.configuration.max_file_size)
        new(path: path, allowed_extensions: allowed_extensions, excluded_directories: excluded_directories,
            max_file_size: max_file_size).call
      end

      def initialize(path:, allowed_extensions:, excluded_directories:, max_file_size:)
        @path = Pathname(path).expand_path
        @allowed_extensions = allowed_extensions.map(&:downcase)
        @excluded_directories = excluded_directories
        @max_file_size = max_file_size.to_i
      end

      def call
        raise MiningError, "path does not exist: #{@path}" unless @path.exist?

        git_files.presence || walked_files
      end

      private

      def git_files
        return [] unless "#{@path}.git".exist?

        output = nil
        Dir.chdir(@path) do
          output = `git ls-files -co --exclude-standard 2>/dev/null`
        end
        output.to_s.lines.map { |line| @path + line.strip }
                         .select { |file| eligible?(file) }
      rescue StandardError
        []
      end

      def walked_files
        files = []
        Find.find(@path.to_s) do |entry|
          path = Pathname(entry)
          if path.directory?
            Find.prune if excluded_directory?(path)
            next
          end
          files << path if eligible?(path)
        end
        files
      end

      def excluded_directory?(path)
        parts = path.expand_path.relative_path_from(@path).each_filename.to_a
        @excluded_directories.any? { |dir| parts.include?(dir) }
      rescue ArgumentError
        false
      end

      def eligible?(path)
        path.file? &&
          @allowed_extensions.include?(path.extname.downcase) &&
          path.size <= @max_file_size &&
          !excluded_directory?(path.dirname)
      rescue OSError
        false
      end
    end
  end
end
