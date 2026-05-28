# frozen_string_literal: true

module Mempalace
  class ReindexDrawerJob < ActiveJob::Base
    queue_as { Mempalace.configuration.embedding_queue }

    def perform(drawer_id)
      drawer = Mempalace::Drawer.find(drawer_id)
      drawer.update!(embedding_status: "pending", embedding_error: nil, embedded_at: nil)
      Mempalace::EmbedDrawerJob.perform_now(drawer.id)
    end
  end
end
