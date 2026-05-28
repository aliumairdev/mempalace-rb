# frozen_string_literal: true

module Mempalace
  module Services
    module Taxonomy
      module_function

      def call(tenant: nil)
        tenant = Mempalace::Tenant.resolve(tenant)
        Mempalace::Wing.for_tenant(tenant).includes(:rooms).to_h do |wing|
          [wing.name, wing.rooms.to_h do |room|
            [room.name, Mempalace::Drawer.for_tenant(tenant).where(room_id: room.id).count]
          end]
        end
      end

      def list_wings(tenant: nil)
        tenant = Mempalace::Tenant.resolve(tenant)
        Mempalace::Wing.for_tenant(tenant).order(:name).map do |wing|
          { id: wing.id, name: wing.name, slug: wing.slug, drawer_count: Mempalace::Drawer.for_tenant(tenant).where(wing_id: wing.id).count }
        end
      end

      def list_rooms(tenant: nil, wing: nil)
        tenant = Mempalace::Tenant.resolve(tenant)
        scope = Mempalace::Room.for_tenant(tenant).includes(:wing).order(:name)
        scope = scope.in_wing(wing) if wing.present?
        scope.map do |room|
          { id: room.id, name: room.name, slug: room.slug, wing: room.wing.slug, drawer_count: Mempalace::Drawer.for_tenant(tenant).where(room_id: room.id).count }
        end
      end
    end
  end
end
