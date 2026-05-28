# frozen_string_literal: true

require_relative "lib/mempalace/version"

Gem::Specification.new do |spec|
  spec.name = "mempalace-rb"
  spec.version = Mempalace::VERSION
  spec.authors = ["Ali Umair"]
  spec.email = ["aliumair.dev@gmail.com"]

  spec.summary = "Rails-native long-term memory for AI agents and Rails apps."
  spec.description = "A Rails engine for tenant-scoped verbatim AI memory with ActiveRecord, keyword search, " \
                     "embeddings, mining, context builders, facts, tunnels, and diary support."
  spec.homepage = "https://github.com/aliumairdev/mempalace-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,db,lib,docs}/**/*", "README.md", "CHANGELOG.md", "LICENSE*"].select { |f| File.file?(f) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activejob", ">= 7.1"
  spec.add_dependency "activerecord", ">= 7.1"
  spec.add_dependency "activesupport", ">= 7.1"
  spec.add_dependency "railties", ">= 7.1"

  spec.add_development_dependency "minitest", ">= 5.20"
  spec.add_development_dependency "parallel", "< 2.1"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rubocop", ">= 1.70"
  spec.add_development_dependency "rubocop-minitest", ">= 0.36"
  spec.add_development_dependency "rubocop-rails", ">= 2.28"
  spec.add_development_dependency "sqlite3", ">= 2.0"
end
