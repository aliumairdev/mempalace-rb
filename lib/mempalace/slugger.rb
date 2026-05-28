# frozen_string_literal: true

module Mempalace
  module Slugger
    module_function

    def call(value)
      value.to_s.downcase.strip
           .gsub(/['"]/, "")
           .gsub(/[^a-z0-9]+/, "-")
           .gsub(/\A-+|-+\z/, "")
           .presence || "general"
    end
  end
end
