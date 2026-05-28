# frozen_string_literal: true

module Mempalace
  class Room < ApplicationRecord
    self.table_name = "mempalace_rooms"

    belongs_to :wing, class_name: "Mempalace::Wing"
    has_many :drawers, class_name: "Mempalace::Drawer", dependent: :destroy
    has_many :closets, class_name: "Mempalace::Closet", dependent: :destroy

    before_validation :normalize_slug
    before_validation :inherit_tenant_from_wing

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: { scope: [:wing_id] }
    validates tenant_foreign_key, presence: true
    validate :wing_matches_tenant

    scope :in_wing, ->(wing_or_slug) {
      next all if wing_or_slug.blank?

      if wing_or_slug.is_a?(Mempalace::Wing)
        where(wing_id: wing_or_slug.id)
      else
        joins(:wing).where(mempalace_wings: { slug: Mempalace::Slugger.call(wing_or_slug) })
      end
    }

    scope :named_or_slugged, ->(value) {
      slug = Mempalace::Slugger.call(value)
      where("LOWER(#{table_name}.name) = ? OR #{table_name}.slug = ?", value.to_s.downcase, slug)
    }

    def self.find_or_create_for_tenant!(wing:, name:, tenant: nil, metadata: {})
      tenant_id = Mempalace.tenant_id_for(tenant)
      raise TenantMismatchError, "wing belongs to another tenant" if wing.tenant_id != tenant_id

      slug = Mempalace::Slugger.call(name)
      found = where(tenant_foreign_key => tenant_id, wing_id: wing.id, slug: slug).first
      return found if found

      create!(tenant_foreign_key => tenant_id, wing: wing, name: name.to_s, slug: slug, metadata: metadata || {})
    rescue ActiveRecord::RecordNotUnique
      where(tenant_foreign_key => tenant_id, wing_id: wing.id, slug: slug).first!
    end

    private

    def normalize_slug
      self.slug = Mempalace::Slugger.call(slug.presence || name)
    end

    def inherit_tenant_from_wing
      self.tenant_id ||= wing&.tenant_id
    end

    def wing_matches_tenant
      return if wing.blank? || tenant_id.blank?

      errors.add(:wing, "belongs to another tenant") if wing.tenant_id != tenant_id
    end
  end
end
