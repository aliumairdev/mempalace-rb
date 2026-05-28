# frozen_string_literal: true

module Mempalace
  module Tunnels
    module Store
      module_function

      def create(source_wing:, source_room:, target_wing:, target_room:, tenant: nil, label: nil, kind: "explicit", metadata: {})
        tenant_id = Mempalace.tenant_id_for(tenant)
        src_wing = Mempalace::Wing.find_or_create_for_tenant!(tenant: tenant, name: source_wing)
        src_room = Mempalace::Room.find_or_create_for_tenant!(tenant: tenant, wing: src_wing, name: source_room)
        tgt_wing = Mempalace::Wing.find_or_create_for_tenant!(tenant: tenant, name: target_wing)
        tgt_room = Mempalace::Room.find_or_create_for_tenant!(tenant: tenant, wing: tgt_wing, name: target_room)

        Mempalace::Tunnel.create!(
          Mempalace::Tenant.foreign_key => tenant_id,
          source_wing: src_wing,
          source_room: src_room,
          target_wing: tgt_wing,
          target_room: tgt_room,
          label: label,
          kind: kind,
          metadata: metadata || {}
        )
      end

      def list(tenant: nil, wing: nil)
        scope = Mempalace::Tunnel.for_tenant(tenant).includes(:source_wing, :source_room, :target_wing, :target_room)
        scope = scope.for_wing(wing) if wing.present?
        scope.to_a
      end

      def follow(wing:, room:, tenant: nil)
        wing_slug = Mempalace::Slugger.call(wing)
        room_slug = Mempalace::Slugger.call(room)
        list(tenant: tenant, wing: wing).select do |tunnel|
          (tunnel.source_wing.slug == wing_slug && tunnel.source_room.slug == room_slug) ||
            (tunnel.target_wing.slug == wing_slug && tunnel.target_room.slug == room_slug)
        end
      end
    end
  end
end
