# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/mempalace/migrations/migrations_generator"
require "generators/mempalace/install/install_generator"

class MempalaceInstallGeneratorTest < Rails::Generators::TestCase
  tests Mempalace::Generators::InstallGenerator
  destination File.expand_path("tmp/generators", __dir__)
  setup :prepare_destination

  def test_install_generator_creates_initializer_and_migration
    run_generator

    assert_file "config/initializers/mempalace.rb" do |content|
      assert_includes content, "config.embedding_provider"
      assert_includes content, "config.tenant_foreign_key"
    end

    assert_predicate Dir[File.join(destination_root, "db/migrate/*_create_mempalace_tables.rb")], :any?
  end
end
