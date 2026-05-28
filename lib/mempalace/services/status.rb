# frozen_string_literal: true

module Mempalace
  module Services
    class Status
      def self.call(tenant: nil)
        tenant_id = Mempalace.tenant_id_for(tenant)
        drawer_scope = Mempalace::Drawer.where(Mempalace::Tenant.foreign_key => tenant_id)
        {
          tenant_id: tenant_id,
          wings: Mempalace::Wing.where(Mempalace::Tenant.foreign_key => tenant_id).count,
          rooms: Mempalace::Room.where(Mempalace::Tenant.foreign_key => tenant_id).count,
          drawers: drawer_scope.count,
          pending_embeddings: drawer_scope.where(embedding_status: "pending").count,
          embedded: drawer_scope.where(embedding_status: "embedded").count,
          failed_embeddings: drawer_scope.where(embedding_status: "failed").count
        }
      end
    end
  end
end
