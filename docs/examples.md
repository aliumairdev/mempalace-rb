# Examples

## Simple Rails App

```ruby
Mempalace.configure do |config|
  config.tenant_mode = :single
end
```

```ruby
Mempalace.remember(
  wing: "Personal CRM",
  room: "contacts",
  content: "Alice prefers email reminders."
)

Mempalace.context_for(query: "How should I remind Alice?", wing: "Personal CRM")
```

## Rails Controller

```ruby
class MessagesController < ApplicationController
  def create
    context = Mempalace.context_for(
      tenant: current_account,
      wing: "AI Receptionist",
      query: params[:message],
      max_tokens: 2_000
    )

    response = Agent.call(message: params[:message], context: context)

    Mempalace.remember_exchange(
      tenant: current_account,
      wing: "AI Receptionist",
      user: params[:message],
      assistant: response.text
    )

    render json: { response: response.text }
  end
end
```

## Facts

```ruby
Mempalace.kg.add(
  tenant: current_account,
  subject: "AI Receptionist",
  predicate: "uses",
  object: "pgvector"
)
```

## Diary

```ruby
Mempalace.diary.write(
  tenant: current_account,
  wing: "AI Receptionist",
  agent_name: "planner",
  entry: "Chose Rails-native storage over ChromaDB."
)
```
