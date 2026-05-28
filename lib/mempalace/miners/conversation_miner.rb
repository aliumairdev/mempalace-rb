# frozen_string_literal: true

module Mempalace
  module Miners
    class ConversationMiner
      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(wing:, tenant: nil, messages: nil, relation: nil, transcript: nil, room: "conversations", async: false)
        @tenant = tenant
        @wing = wing
        @messages = messages || relation
        @transcript = transcript
        @room = room
        @async = async
      end

      def call
        if @async
          messages = Array(@messages).map { |message| serialize_message(message) }
          job = Mempalace::MineConversationJob.perform_later(
            tenant_id: Mempalace.tenant_id_for(@tenant),
            messages: messages,
            wing: @wing,
            options: { room: @room }
          )
          return { job_id: job.job_id }
        end

        chunks = if @transcript.present?
                   Mempalace::Chunking::ConversationChunker.call(@transcript)
                 else
                   Mempalace::Chunking::ConversationChunker.call(@messages)
                 end

        drawers = chunks.map do |chunk|
          Mempalace.remember(
            tenant: @tenant,
            wing: @wing,
            room: @room,
            content: chunk[:content],
            memory_type: "conversation",
            source_type: "conversation",
            chunk_index: chunk[:chunk_index],
            metadata: (chunk[:metadata] || {}).merge(mined_from: "conversation")
          )
        end
        { drawers: drawers.length, drawer_ids: drawers.map(&:id) }
      end

      private

      def serialize_message(message)
        {
          id: read(message, :id),
          role: read(message, :role),
          content: read(message, :content),
          created_at: read(message, :created_at).to_s
        }
      end

      def read(message, key)
        return message[key] if message.respond_to?(:key?) && message.key?(key)
        return message[key.to_s] if message.respond_to?(:key?) && message.key?(key.to_s)
        return message.public_send(key) if message.respond_to?(key)

        nil
      end
    end
  end
end
