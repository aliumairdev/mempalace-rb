# Embedding Providers

All providers implement:

```ruby
embed(text) # returns Array<Float> or nil
```

## Null

```ruby
config.embedding_provider = :null
```

Default null mode returns `nil`, so drawers are marked `skipped`. Deterministic mode creates local lexical vectors for tests.

## OpenAI

```ruby
config.embedding_provider = :openai
config.embedding_model = "text-embedding-3-small"
config.openai_api_key = ENV["OPENAI_API_KEY"]
```

## OpenRouter

```ruby
config.embedding_provider = :openrouter
config.embedding_model = "openai/text-embedding-3-small"
config.openrouter_api_key = ENV["OPENROUTER_API_KEY"]
```

## Ollama

```ruby
config.embedding_provider = :ollama
config.embedding_model = "nomic-embed-text"
config.ollama_base_url = "http://localhost:11434"
```

## RubyLLM

```ruby
config.embedding_provider = :ruby_llm
config.embedding_model = "text-embedding-3-small"
```

Embedding failures mark the drawer as `failed`, record `embedding_error`, and preserve the original drawer.
