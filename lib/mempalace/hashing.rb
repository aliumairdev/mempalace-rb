# frozen_string_literal: true

require "digest"

module Mempalace
  module Hashing
    module_function

    def content_sha256(content)
      Digest::SHA256.hexdigest(content.to_s)
    end

    def normalized_content(content)
      content.to_s.downcase.scan(/[[:alnum:]_]+/).join(" ")
    end

    def normalized_content_sha256(content)
      Digest::SHA256.hexdigest(normalized_content(content))
    end
  end
end
