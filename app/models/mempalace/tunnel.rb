# frozen_string_literal: true

module Mempalace
  class Tunnel < ApplicationRecord
    self.table_name = "mempalace_tunnels"

    belongs_to :source_wing, class_name: "Mempalace::Wing"
    belongs_to :source_room, class_name: "Mempalace::Room"
    belongs_to :target_wing, class_name: "Mempalace::Wing"
    belongs_to :target_room, class_name: "Mempalace::Room"

    before_validation :inherit_tenant

    validates tenant_foreign_key, presence: true
    validates :kind, presence: true
    validate :endpoints_match_tenant

    scope :for_wing, ->(wing_or_slug) {
      slug = Mempalace::Slugger.call(wing_or_slug)
      joins("INNER JOIN mempalace_wings source_wings ON source_wings.id = mempalace_tunnels.source_wing_id")
        .joins("INNER JOIN mempalace_wings target_wings ON target_wings.id = mempalace_tunnels.target_wing_id")
        .where("source_wings.slug = :slug OR target_wings.slug = :slug", slug: slug)
    }

    private

    def inherit_tenant
      self.tenant_id ||= source_wing&.tenant_id || target_wing&.tenant_id
    end

    def endpoints_match_tenant
      [source_wing, source_room, target_wing, target_room].compact.each do |record|
        errors.add(:base, "tunnel endpoint belongs to another tenant") if record.tenant_id != tenant_id
      end
    end
  end
end
