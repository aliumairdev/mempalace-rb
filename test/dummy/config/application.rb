# frozen_string_literal: true

require "rails"
require "active_record/railtie"
require "active_job/railtie"
require "logger"

require_relative "../../../lib/mempalace"

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.1
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.secret_key_base = "test"
    config.logger = Logger.new(nil)
    config.active_job.queue_adapter = :inline
  end
end
