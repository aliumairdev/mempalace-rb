# Mining Projects

```ruby
Mempalace.mine_project(
  tenant: current_account,
  path: Rails.root,
  wing: "My Rails App"
)
```

The project miner:

- Respects configured allowed extensions.
- Skips generated/cache directories.
- Skips files larger than `config.max_file_size`.
- Chunks text by paragraph.
- Detects rooms from file paths.
- Stores source file, line range, and chunk index metadata.

Default skipped directories include `.git`, `node_modules`, `tmp`, `log`, `storage`, `vendor/bundle`, `.next`, `dist`, `build`, and `coverage`.
