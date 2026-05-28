# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Mempalace
  module Generators
    class MigrationsGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def copy_migration
        migration_template "create_mempalace_tables.rb.tt", "db/migrate/create_mempalace_tables.rb"
      end
    end
  end
end
