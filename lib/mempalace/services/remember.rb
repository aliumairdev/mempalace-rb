# frozen_string_literal: true

module Mempalace
  module Services
    class Remember
      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(wing:, room:, content:, tenant: nil, memory_type: "general", source_type: "manual",
                     source_id: nil, source_file: nil, chunk_index: 0, line_start: nil, line_end: nil,
                     filed_at: nil, metadata: {}, enqueue_embedding: nil, build_closet: false)
        @tenant = tenant
        @wing_name = wing
        @room_name = room
        @content = content
        @memory_type = memory_type
        @source_type = source_type
        @source_id = source_id
        @source_file = source_file
        @chunk_index = chunk_index
        @line_start = line_start
        @line_end = line_end
        @filed_at = filed_at
        @metadata = metadata || {}
        @enqueue_embedding = enqueue_embedding
        @build_closet = build_closet
      end

      def call
        tenant_id = Mempalace.tenant_id_for(@tenant)
        raise ValidationError, "content is required" if @content.blank?
        raise ValidationError, "wing is required" if @wing_name.blank?
        raise ValidationError, "room is required" if @room_name.blank?

        normalized_hash = Mempalace::Hashing.normalized_content_sha256(@content)
        existing = Mempalace::Drawer.where(Mempalace::Tenant.foreign_key => tenant_id, normalized_content_sha256: normalized_hash).first
        return existing if existing

        wing = Mempalace::Wing.find_or_create_for_tenant!(tenant: @tenant, name: @wing_name)
        room = Mempalace::Room.find_or_create_for_tenant!(tenant: @tenant, wing: wing, name: @room_name)

        drawer = Mempalace::Drawer.create!(
          Mempalace::Tenant.foreign_key => tenant_id,
          wing: wing,
          room: room,
          content: @content.to_s,
          content_sha256: Mempalace::Hashing.content_sha256(@content),
          normalized_content_sha256: normalized_hash,
          memory_type: @memory_type.presence || "general",
          source_type: @source_type,
          source_id: @source_id,
          source_file: @source_file,
          chunk_index: @chunk_index || 0,
          line_start: @line_start,
          line_end: @line_end,
          filed_at: @filed_at || Time.current,
          metadata: @metadata,
          embedding_status: "pending"
        )

        enqueue_embedding(drawer)
        Mempalace::Closets::Builder.call(drawers: [drawer]) if @build_closet
        drawer
      rescue ActiveRecord::RecordNotUnique
        Mempalace::Drawer.where(Mempalace::Tenant.foreign_key => tenant_id, normalized_content_sha256: normalized_hash).first!
      end

      private

      def enqueue_embedding(drawer)
        should_enqueue = @enqueue_embedding.nil? ? Mempalace.configuration.auto_embed : @enqueue_embedding
        return unless should_enqueue

        Mempalace::EmbedDrawerJob.perform_later(drawer.id)
      end
    end
  end
end
