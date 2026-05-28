# frozen_string_literal: true

module Mempalace
  module Search
    module Scorer
      module_function

      def tokenize(text)
        text.to_s.downcase.scan(/[[:alnum:]_]{2,}/)
      end

      def keyword_score(query, content)
        terms = tokenize(query).uniq
        return 0.0 if terms.empty?

        haystack = content.to_s.downcase
        matches = terms.count { |term| haystack.include?(term) }
        matches.to_f / terms.length
      end

      def cosine_similarity(left, right)
        return 0.0 if left.blank? || right.blank? || left.length != right.length

        dot = 0.0
        a_norm = 0.0
        b_norm = 0.0
        left.each_with_index do |value, index|
          av = value.to_f
          bv = right[index].to_f
          dot += av * bv
          a_norm += av * av
          b_norm += bv * bv
        end
        return 0.0 if a_norm.zero? || b_norm.zero?

        dot / (Math.sqrt(a_norm) * Math.sqrt(b_norm))
      end

      def recency_score(time)
        return 0.0 if time.blank?

        age_days = [(Time.current - time) / 1.day, 0].max
        Math.exp(-age_days / 90.0)
      end
    end
  end
end
