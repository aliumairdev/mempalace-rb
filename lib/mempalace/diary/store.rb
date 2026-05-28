# frozen_string_literal: true

module Mempalace
  module Diary
    module Store
      module_function

      def write(agent_name:, entry:, tenant: nil, topic: "general", wing: nil, metadata: {})
        tenant_id = Mempalace.tenant_id_for(tenant)
        wing_record = (Mempalace::Wing.find_or_create_for_tenant!(tenant: tenant, name: wing) if wing.present?)

        Mempalace::DiaryEntry.create!(
          Mempalace::Tenant.foreign_key => tenant_id,
          wing: wing_record,
          agent_name: agent_name,
          topic: topic,
          entry: entry,
          written_at: Time.current,
          metadata: metadata || {}
        )
      end

      def read(agent_name:, tenant: nil, last_n: 10, wing: nil)
        scope = Mempalace::DiaryEntry.for_tenant(tenant).for_agent(agent_name).recent_first
        if wing.present?
          wing_record = Mempalace::Wing.for_tenant(tenant).where(slug: Mempalace::Slugger.call(wing)).first
          scope = scope.where(wing_id: wing_record&.id)
        end
        scope.limit(last_n).to_a
      end
    end
  end
end
