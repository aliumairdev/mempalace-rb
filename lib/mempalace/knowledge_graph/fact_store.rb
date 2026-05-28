# frozen_string_literal: true

module Mempalace
  module KnowledgeGraph
    module FactStore
      module_function

      def add(subject:, predicate:, object:, tenant: nil, valid_from: nil, valid_to: nil, source_drawer_id: nil, metadata: {})
        tenant_id = Mempalace.tenant_id_for(tenant)
        Mempalace::Fact.create!(
          Mempalace::Tenant.foreign_key => tenant_id,
          subject: subject,
          predicate: predicate,
          object: object,
          valid_from: valid_from,
          valid_to: valid_to,
          source_drawer_id: source_drawer_id,
          metadata: metadata || {}
        )
      end

      def query(entity:, tenant: nil, as_of: Time.current, direction: :both)
        scope = Mempalace::Fact.for_tenant(tenant)
        scope = case direction.to_sym
                when :outgoing
                  scope.where("LOWER(subject) = ?", entity.to_s.downcase)
                when :incoming
                  scope.where("LOWER(object) = ?", entity.to_s.downcase)
                else
                  scope.for_entity(entity)
                end
        scope.select { |fact| fact.current?(at: as_of) }
      end

      def invalidate(subject:, predicate:, object:, tenant: nil, ended: Time.current)
        facts = Mempalace::Fact.for_tenant(tenant)
                               .where(subject: subject, predicate: predicate, object: object, valid_to: nil)
        facts.find_each { |fact| fact.update!(valid_to: ended) }
        facts
      end

      def timeline(tenant: nil, entity: nil)
        scope = Mempalace::Fact.for_tenant(tenant).order(Arel.sql("COALESCE(valid_from, created_at) ASC"))
        scope = scope.for_entity(entity) if entity.present?
        scope.to_a
      end
    end
  end
end
