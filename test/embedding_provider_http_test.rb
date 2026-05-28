# frozen_string_literal: true

require "test_helper"
require "faraday"

class EmbeddingProviderHttpTest < MempalaceTest
  Response = Struct.new(:status, :body, keyword_init: true) do
    def success?
      status.between?(200, 299)
    end
  end

  Options = Struct.new(:timeout)
  Request = Struct.new(:headers, :options, :body, keyword_init: true)

  def test_openai_provider_posts_expected_payload_and_parses_vector
    captured = with_faraday_post(status: 200, body: { data: [{ embedding: [0.1, 0.2] }] }.to_json) do
      Mempalace.configure do |config|
        config.openai_api_key = "test-key"
        config.embedding_model = "text-embedding-test"
      end

      assert_equal [0.1, 0.2], Mempalace::Embedding::OpenAiProvider.new.embed("hello")
    end

    assert_equal "https://api.openai.com/v1/embeddings", captured[:url]
    assert_equal "Bearer test-key", captured[:request].headers["Authorization"]
    assert_equal({ "model" => "text-embedding-test", "input" => "hello" }, JSON.parse(captured[:request].body))
  end

  def test_openrouter_provider_uses_configured_base_url
    Mempalace.configure do |config|
      config.openrouter_api_key = "router-key"
      config.openrouter_base_url = "https://example.test/v1"
      config.embedding_model = "openai/test"
    end

    captured = with_faraday_post(status: 200, body: { data: [{ embedding: [1, 2, 3] }] }.to_json) do
      assert_equal [1.0, 2.0, 3.0], Mempalace::Embedding::OpenRouterProvider.new.embed("route")
    end

    assert_equal "https://example.test/v1/embeddings", captured[:url]
    assert_equal "Bearer router-key", captured[:request].headers["Authorization"]
  end

  def test_ollama_provider_parses_embedding_response
    Mempalace.configure do |config|
      config.ollama_base_url = "http://ollama.test"
      config.embedding_model = "nomic-test"
    end

    captured = with_faraday_post(status: 200, body: { embedding: [0.4, 0.5] }.to_json) do
      assert_equal [0.4, 0.5], Mempalace::Embedding::OllamaProvider.new.embed("local")
    end

    assert_equal "http://ollama.test/api/embeddings", captured[:url]
    assert_equal({ "model" => "nomic-test", "prompt" => "local" }, JSON.parse(captured[:request].body))
  end

  def test_http_provider_raises_on_bad_status
    Mempalace.configure { |config| config.openai_api_key = "test-key" }

    with_faraday_post(status: 500, body: "{}") do
      error = assert_raises(Mempalace::EmbeddingError) do
        Mempalace::Embedding::OpenAiProvider.new.embed("hello")
      end

      assert_includes error.message, "HTTP 500"
    end
  end

  private

  def with_faraday_post(status:, body:)
    captured = {}
    original = Faraday.method(:post)

    Faraday.define_singleton_method(:post) do |url, &request_block|
      request = Request.new(headers: {}, options: Options.new, body: nil)
      request_block.call(request)
      captured[:url] = url
      captured[:request] = request
      Response.new(status: status, body: body)
    end

    yield
    captured
  ensure
    Faraday.define_singleton_method(:post, original)
  end
end
