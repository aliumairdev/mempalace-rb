# frozen_string_literal: true

require "rails/generators"

module Mempalace
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "initializer.rb", "config/initializers/mempalace.rb"
      end

      def copy_migrations
        invoke "mempalace:migrations"
      end
    end
  end
end
