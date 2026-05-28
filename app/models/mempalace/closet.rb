# frozen_string_literal: true

require "json"

module Mempalace
  class Closet < ApplicationRecord
    self.table_name = "mempalace_closets"

    belongs_to :wing, class_name: "Mempalace::Wing"
    belongs_to :room, class_name: "Mempalace::Room"

    before_validation :inherit_tenant

    validates tenant_foreign_key, presence: true
    validates :pointer_text, presence: true
    validate :wing_and_room_match_tenant

    scope :in_wing, ->(wing_or_slug) {
      wing_or_slug.present? ? joins(:wing).where(mempalace_wings: { slug: Mempalace::Slugger.call(wing_or_slug) }) : all
    }
    scope :in_room, ->(room_or_slug) {
      room_or_slug.present? ? joins(:room).where(mempalace_rooms: { slug: Mempalace::Slugger.call(room_or_slug) }) : all
    }

    def drawer_ids
      normalize_array(super)
    end

    def entities
      normalize_array(super)
    end

    def topics
      normalize_array(super)
    end

    private

    def normalize_array(value)
      case value
      when Array
        value
      when String
        JSON.parse(value)
      else
        []
      end
    rescue JSON::ParserError
      []
    end

    def inherit_tenant
      self.tenant_id ||= wing&.tenant_id || room&.tenant_id
    end

    def wing_and_room_match_tenant
      return if tenant_id.blank?

      errors.add(:wing, "belongs to another tenant") if wing && wing.tenant_id != tenant_id
      errors.add(:room, "belongs to another tenant") if room && room.tenant_id != tenant_id
    end
  end
end
