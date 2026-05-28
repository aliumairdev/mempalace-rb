# Mining Conversations

```ruby
Mempalace.mine_conversation(
  tenant: current_account,
  wing: "Support Bot",
  conversation: messages
)
```

Supported inputs:

- Array of hashes with `role`, `content`, `id`, and `created_at`.
- Rails-like objects that respond to those methods.
- Plain transcript text.

The miner groups user and assistant exchanges where possible and stores each exchange verbatim.
