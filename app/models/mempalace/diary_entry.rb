# frozen_string_literal: true

module Mempalace
  class DiaryEntry < ApplicationRecord
    self.table_name = "mempalace_diary_entries"

    belongs_to :wing, class_name: "Mempalace::Wing", optional: true

    before_validation :set_defaults

    validates tenant_foreign_key, presence: true
    validates :agent_name, :entry, :topic, :written_at, presence: true

    scope :for_agent, ->(agent_name) { where(agent_name: agent_name.to_s.downcase) }
    scope :recent_first, -> { order(written_at: :desc, id: :desc) }

    private

    def set_defaults
      self.agent_name = agent_name.to_s.downcase if agent_name.present?
      self.topic = "general" if topic.blank?
      self.written_at ||= Time.current
      self.metadata ||= {}
    end
  end
end
