# frozen_string_literal: true

require "json"

module Mempalace
  class Drawer < ApplicationRecord
    self.table_name = "mempalace_drawers"

    belongs_to :wing, class_name: "Mempalace::Wing"
    belongs_to :room, class_name: "Mempalace::Room"
    has_many :facts, class_name: "Mempalace::Fact", foreign_key: :source_drawer_id, dependent: :nullify

    before_validation :set_defaults
    before_validation :inherit_tenant
    before_validation :compute_hashes

    validates :content, presence: true
    validates :content_sha256, presence: true
    validates :normalized_content_sha256, presence: true
    validates :memory_type, presence: true
    validates :embedding_status, presence: true
    validates :filed_at, presence: true
    validates tenant_foreign_key, presence: true
    validate :wing_and_room_match_tenant
    validate :room_belongs_to_wing

    scope :in_wing, ->(wing_or_slug) {
      next all if wing_or_slug.blank?

      if wing_or_slug.is_a?(Mempalace::Wing)
        where(wing_id: wing_or_slug.id)
      else
        joins(:wing).where(mempalace_wings: { slug: Mempalace::Slugger.call(wing_or_slug) })
      end
    }

    scope :in_room, ->(room_or_slug) {
      next all if room_or_slug.blank?

      if room_or_slug.is_a?(Mempalace::Room)
        where(room_id: room_or_slug.id)
      else
        joins(:room).where(mempalace_rooms: { slug: Mempalace::Slugger.call(room_or_slug) })
      end
    }

    scope :of_memory_type, ->(type) { type.present? ? where(memory_type: type.to_s) : all }
    scope :from_source, ->(source_type) { source_type.present? ? where(source_type: source_type.to_s) : all }
    scope :embedded, -> { where(embedding_status: "embedded") }
    scope :embedding_failed, -> { where(embedding_status: "failed") }
    scope :pending_embedding, -> { where(embedding_status: "pending") }

    def self.filtered(tenant:, wing: nil, room: nil, memory_type: nil, source_type: nil)
      for_tenant(tenant)
        .in_wing(wing)
        .in_room(room)
        .of_memory_type(memory_type)
        .from_source(source_type)
    end

    def duplicate_hash
      normalized_content_sha256
    end

    def embedding_vector
      case embedding
      when Array
        embedding.map(&:to_f)
      when String
        return [] if embedding.blank?

        JSON.parse(embedding).map(&:to_f)
      else
        []
      end
    rescue JSON::ParserError, TypeError
      []
    end

    def embedding_vector=(vector)
      self.embedding = if self.class.native_vector_column?
                         vector
                       else
                         Array(vector).map(&:to_f).to_json
                       end
    end

    def self.native_vector_column?
      connection.adapter_name.downcase.include?("postgres") &&
        columns_hash["embedding"]&.sql_type.to_s.start_with?("vector")
    rescue ActiveRecord::ConnectionNotEstablished
      false
    end

    def mark_embedded!(vector:, model:)
      self.embedding_vector = vector
      update!(
        embedding: embedding,
        embedding_model: model,
        embedding_status: "embedded",
        embedding_error: nil,
        embedded_at: Time.current
      )
    end

    def mark_embedding_failed!(error)
      update!(
        embedding_status: "failed",
        embedding_error: error.to_s.truncate(500),
        embedded_at: nil
      )
    end

    def mark_embedding_skipped!
      update!(
        embedding_status: "skipped",
        embedding_error: nil,
        embedded_at: nil
      )
    end

    private

    def set_defaults
      self.memory_type = "general" if memory_type.blank?
      self.embedding_status = "pending" if embedding_status.blank?
      self.filed_at ||= Time.current
      self.metadata ||= {}
    end

    def inherit_tenant
      self.tenant_id ||= wing&.tenant_id || room&.tenant_id
    end

    def compute_hashes
      return if content.blank?

      self.content_sha256 ||= Mempalace::Hashing.content_sha256(content)
      self.normalized_content_sha256 ||= Mempalace::Hashing.normalized_content_sha256(content)
    end

    def wing_and_room_match_tenant
      return if tenant_id.blank?

      errors.add(:wing, "belongs to another tenant") if wing && wing.tenant_id != tenant_id
      errors.add(:room, "belongs to another tenant") if room && room.tenant_id != tenant_id
    end

    def room_belongs_to_wing
      return if wing.blank? || room.blank?

      errors.add(:room, "does not belong to wing") if room.wing_id != wing.id
    end
  end
end
