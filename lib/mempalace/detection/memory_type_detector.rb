# frozen_string_literal: true

module Mempalace
  module Detection
    class MemoryTypeDetector
      PATTERNS = {
        "decision" => /\b(decided|choose|chose|use|went with|architecture|stack|because|instead of)\b/i,
        "preference" => /\b(always|never|prefer|preference|don't|do not|style|convention)\b/i,
        "milestone" => /\b(shipped|launched|deployed|released|implemented|works|fixed|solved|finally)\b/i,
        "problem" => /\b(error|bug|failed|failure|broken|issue|problem|crash|root cause|fix)\b/i,
        "event" => /\b(today|yesterday|tomorrow|on \d{4}-\d{2}-\d{2}|meeting|call)\b/i
      }.freeze

      def self.call(content)
        PATTERNS.each do |type, pattern|
          return type if content.to_s.match?(pattern)
        end
        "general"
      end
    end
  end
end
