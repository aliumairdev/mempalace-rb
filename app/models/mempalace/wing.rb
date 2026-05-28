# frozen_string_literal: true

module Mempalace
  class Wing < ApplicationRecord
    self.table_name = "mempalace_wings"

    has_many :rooms, class_name: "Mempalace::Room", dependent: :destroy
    has_many :drawers, class_name: "Mempalace::Drawer", dependent: :destroy
    has_many :closets, class_name: "Mempalace::Closet", dependent: :destroy

    before_validation :normalize_slug

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: { scope: tenant_foreign_key }
    validates tenant_foreign_key, presence: true

    scope :named_or_slugged, ->(value) {
      slug = Mempalace::Slugger.call(value)
      where("LOWER(name) = ? OR slug = ?", value.to_s.downcase, slug)
    }

    def self.find_or_create_for_tenant!(name:, tenant: nil, metadata: {})
      tenant_id = Mempalace.tenant_id_for(tenant)
      slug = Mempalace::Slugger.call(name)
      found = where(tenant_foreign_key => tenant_id, slug: slug).first
      return found if found

      create!(tenant_foreign_key => tenant_id, name: name.to_s, slug: slug, metadata: metadata || {})
    rescue ActiveRecord::RecordNotUnique
      where(tenant_foreign_key => tenant_id, slug: slug).first!
    end

    private

    def normalize_slug
      self.slug = Mempalace::Slugger.call(slug.presence || name)
    end
  end
end
