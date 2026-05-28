# frozen_string_literal: true

module Mempalace
  class MineConversationJob < ActiveJob::Base
    queue_as :default

    def perform(tenant_id:, messages:, wing:, options: {})
      Mempalace.mine_conversation(tenant: tenant_id, messages: messages, wing: wing, async: false, **options.symbolize_keys)
    end
  end
end
