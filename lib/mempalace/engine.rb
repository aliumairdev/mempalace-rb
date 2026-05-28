# frozen_string_literal: true

require "rails/engine"

module Mempalace
  class Engine < ::Rails::Engine
    isolate_namespace Mempalace

    config.mempalace = ActiveSupport::OrderedOptions.new

    initializer "mempalace.load_app_paths" do
      ActiveSupport.on_load(:active_record) do
        require "mempalace"
      end
    end

    rake_tasks do
      load File.expand_path("../tasks/mempalace.rake", __dir__)
    end
  end
end
