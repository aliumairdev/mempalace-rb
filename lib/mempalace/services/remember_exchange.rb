# frozen_string_literal: true

module Mempalace
  module Services
    class RememberExchange
      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(wing:, tenant: nil, room: "conversations", user: nil, assistant: nil, messages: nil,
                     occurred_at: nil, source_type: "conversation", source_id: nil, metadata: {})
        @tenant = tenant
        @wing = wing
        @room = room
        @user = user
        @assistant = assistant
        @messages = messages
        @occurred_at = occurred_at
        @source_type = source_type
        @source_id = source_id
        @metadata = metadata || {}
      end

      def call
        content = if @messages.present?
                    Array(@messages).map { |message| format_message(message) }.join("\n")
                  else
                    [
                      ("User: #{@user}" if @user.present?),
                      ("Assistant: #{@assistant}" if @assistant.present?)
                    ].compact.join("\n")
                  end

        raise ValidationError, "exchange content is required" if content.blank?

        Mempalace.remember(
          tenant: @tenant,
          wing: @wing,
          room: @room,
          content: content,
          memory_type: "conversation",
          source_type: @source_type,
          source_id: @source_id,
          filed_at: @occurred_at,
          metadata: @metadata.merge(exchange: true)
        )
      end

      private

      def format_message(message)
        role = read(message, :role) || read(message, :speaker) || "message"
        content = read(message, :content) || read(message, :body) || message.to_s
        "#{role.to_s.capitalize}: #{content}"
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
