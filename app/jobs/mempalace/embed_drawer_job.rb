# frozen_string_literal: true

module Mempalace
  class EmbedDrawerJob < ActiveJob::Base
    queue_as { Mempalace.configuration.embedding_queue }

    def perform(drawer_id)
      drawer = Mempalace::Drawer.find(drawer_id)
      provider = Mempalace::Embedding::ProviderFactory.build
      vector = provider.embed(drawer.content)

      if vector.blank?
        drawer.mark_embedding_skipped!
      else
        drawer.mark_embedded!(vector: vector, model: Mempalace.configuration.embedding_model)
      end
    rescue StandardError => e
      raise unless defined?(drawer) && drawer

      drawer.mark_embedding_failed!(e)
    end
  end
end
