# frozen_string_literal: true

module Mempalace
  class Fact < ApplicationRecord
    self.table_name = "mempalace_facts"

    belongs_to :source_drawer, class_name: "Mempalace::Drawer", optional: true

    validates tenant_foreign_key, presence: true
    validates :subject, :predicate, :object, presence: true

    scope :current, -> {
      now = Time.current
      where("valid_from IS NULL OR valid_from <= ?", now)
        .where("valid_to IS NULL OR valid_to >= ?", now)
    }
    scope :for_entity, ->(entity) {
      where("LOWER(subject) = :entity OR LOWER(object) = :entity", entity: entity.to_s.downcase)
    }

    def current?(at: Time.current)
      (valid_from.blank? || valid_from <= at) && (valid_to.blank? || valid_to >= at)
    end
  end
end
