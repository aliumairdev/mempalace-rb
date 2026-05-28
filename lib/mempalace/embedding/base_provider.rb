# frozen_string_literal: true

module Mempalace
  module Embedding
    class BaseProvider
      def embed(_text)
        raise NotImplementedError, "#{self.class.name} must implement #embed"
      end
    end
  end
end
