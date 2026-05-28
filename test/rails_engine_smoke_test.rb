# frozen_string_literal: true

require "test_helper"
require "open3"

class RailsEngineSmokeTest < MempalaceTest
  def test_dummy_rails_app_loads_engine
    output, status = Open3.capture2e(
      { "RAILS_ENV" => "test" },
      Gem.ruby,
      "-Ilib",
      "test/dummy/bin/rails",
      "runner",
      "puts Mempalace::Engine.engine_name; puts Mempalace.configuration.embedding_provider"
    )

    assert_predicate status, :success?, output
    assert_includes output, "mempalace"
    assert_includes output, "null"
  end
end
