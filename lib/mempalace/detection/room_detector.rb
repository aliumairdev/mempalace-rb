# frozen_string_literal: true

module Mempalace
  module Detection
    class RoomDetector
      DEFAULT_KEYWORDS = {
        "architecture" => %w[architecture stack framework database api infrastructure pgvector sidekiq redis postgres],
        "billing" => %w[billing invoice stripe subscription payment plan],
        "auth" => %w[auth authentication authorization login password oauth session],
        "search" => %w[search vector embedding keyword pgvector semantic],
        "conversations" => %w[user assistant message conversation transcript]
      }.freeze

      def self.call(path: nil, content: "", rooms: nil)
        new(path: path, content: content, rooms: rooms).call
      end

      def initialize(path:, content:, rooms:)
        @path = path.to_s.downcase
        @content = content.to_s.downcase
        @rooms = Array(rooms).presence || DEFAULT_KEYWORDS.keys
      end

      def call
        room_names = @rooms.map { |room| room.respond_to?(:name) ? room.name : room.to_s }
        room_names.each do |room|
          slug = Mempalace::Slugger.call(room)
          return room if @path.include?(slug) || @path.include?(room.to_s.downcase)
        end

        scores = Hash.new(0)
        room_names.each do |room|
          keywords = DEFAULT_KEYWORDS.fetch(Mempalace::Slugger.call(room), [room.to_s])
          keywords.each { |keyword| scores[room] += @content.scan(keyword).length }
        end
        best = scores.max_by { |_room, score| score }
        best && best[1].positive? ? best[0] : "general"
      end
    end
  end
end
