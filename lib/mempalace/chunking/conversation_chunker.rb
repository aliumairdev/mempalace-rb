# frozen_string_literal: true

module Mempalace
  module Chunking
    class ConversationChunker
      def self.call(input)
        new(input).call
      end

      def initialize(input)
        @input = input
      end

      def call
        if @input.is_a?(String)
          from_transcript(@input)
        else
          from_messages(Array(@input))
        end
      end

      private

      def from_transcript(text)
        paragraphs = text.to_s.split(/\n{2,}/).map(&:strip).compact_blank
        paragraphs.each_with_index.map do |content, index|
          { content: content, chunk_index: index }
        end
      end

      def from_messages(messages)
        chunks = []
        index = 0
        while index < messages.length
          current = messages[index]
          role = read(current, :role).to_s
          if role == "user" && messages[index + 1] && read(messages[index + 1], :role).to_s == "assistant"
            chunks << {
              content: "User: #{read(current, :content)}\nAssistant: #{read(messages[index + 1], :content)}",
              chunk_index: chunks.length,
              metadata: message_metadata(current).merge(next_message: message_metadata(messages[index + 1]))
            }
            index += 2
          else
            chunks << {
              content: "#{role.presence || 'Message'}: #{read(current, :content)}",
              chunk_index: chunks.length,
              metadata: message_metadata(current)
            }
            index += 1
          end
        end
        chunks
      end

      def read(message, key)
        return message[key] if message.respond_to?(:key?) && message.key?(key)
        return message[key.to_s] if message.respond_to?(:key?) && message.key?(key.to_s)
        return message.public_send(key) if message.respond_to?(key)

        nil
      end

      def message_metadata(message)
        {
          message_id: read(message, :id),
          role: read(message, :role),
          created_at: read(message, :created_at).to_s.presence
        }.compact
      end
    end
  end
end
