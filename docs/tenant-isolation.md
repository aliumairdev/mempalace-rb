# Tenant Modes

`mempalace-rb` supports both simple and multitenant Rails apps.

## Single Mode

Use this for a normal app with one memory space and no `Account` model:

```ruby
Mempalace.configure do |config|
  config.tenant_mode = :single
end
```

Then `tenant:` is optional. The gem stores memories under `config.single_tenant_id`, which defaults to `0`.

## Multi Mode

Use this for SaaS, account-scoped, client-scoped, or tenant-scoped apps:

```ruby
Mempalace.configure do |config|
  config.tenant_mode = :multi
  config.tenant_model = "Account"
  config.tenant_foreign_key = :account_id
end
```

In multi mode, every public read/write API requires `tenant:` unless you configure and use your own tenant resolver.

Safeguards:

- Models validate the configured tenant foreign key.
- Public services resolve tenant ids before querying.
- Search and miners use tenant-scoped drawers, rooms, and wings.
- Duplicate detection is tenant-scoped.
- Tests cover cross-tenant search and duplicate boundaries.

Recommended app practice:

- Pass `current_account` or equivalent to every call.
- Avoid unscoped `Mempalace::Drawer` reads in application code.
- Keep unique indexes scoped by tenant.
