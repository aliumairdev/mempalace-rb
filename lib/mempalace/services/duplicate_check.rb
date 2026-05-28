# frozen_string_literal: true

module Mempalace
  module Services
    class DuplicateCheck
      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(content:, tenant: nil, threshold: 0.9, limit: 5)
        @tenant = tenant
        @content = content
        @threshold = threshold
        @limit = limit
      end

      def call
        tenant_id = Mempalace.tenant_id_for(@tenant)
        raise ValidationError, "content is required" if @content.blank?

        normalized_hash = Mempalace::Hashing.normalized_content_sha256(@content)
        exact = Mempalace::Drawer.where(Mempalace::Tenant.foreign_key => tenant_id,
                                        normalized_content_sha256: normalized_hash).limit(@limit).to_a
        return { duplicate: true, matches: exact.map { |drawer| ResultFormatter.drawer(drawer, score: 1.0) } } if exact.any?

        semantic_matches = Mempalace.semantic_search(tenant: @tenant, query: @content, limit: @limit)
                                    .select { |result| result[:score].to_f >= @threshold.to_f }

        { duplicate: semantic_matches.any?, matches: semantic_matches }
      end
    end
  end
end
