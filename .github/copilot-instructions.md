# Copilot Instructions for SmartCacheTenant

## Project identity

- This repository is a Ruby gem, not a Rails application.
- The gem's purpose is to add tenant-aware caching to ActiveRecord reads using `Rails.cache`.
- Supported stack: Ruby >= 3.3, Rails >= 7.0, < 8.0.
- Main entry point: `lib/smart_cache_tenant.rb` and the modules under `lib/smart_cache_tenant/`.
- Public configuration API: `SmartCacheTenant.configure do |config| ... end`.
- Default configuration is defined in `lib/smart_cache_tenant/configuration.rb`.

## Architecture

- The gem integrates with Rails through `lib/smart_cache_tenant/railtie.rb`.
- On ActiveRecord load, it prepends `SmartCacheTenant::CacheableRelation` into `ActiveRecord::Relation`.
- It prepends `SmartCacheTenant::CacheablePersistence` into `ActiveRecord::Base` to support bulk write invalidation.
- Cache invalidation is version-based, not query-key deletion-based.
- `SmartCacheTenant::VersionStore` stores per-model and per-tenant version tokens in `Rails.cache`.
- `SmartCacheTenant::ModelCallbacks` adds `after_commit` invalidation for record create/update/delete operations.
- `SmartCacheTenant::CacheableRelation` handles three cached read operations: `load`, `calculate`, and `exists?`.

## Current patterns to preserve

### Cache strategy

- Prefer version keys over direct invalidation of query keys.
- Cache keys include: database name, SQL fingerprint, tenant, operation, and model version tokens.
- Reads are only cached when `SmartCacheTenant.config.enabled` is `true` and all involved models opt in with `has_smart_cache`.
- If a relation is not cache-enabled, fallback to the native ActiveRecord behavior.

### Tenant handling

- The project treats `tenant_column` as the canonical tenant discriminator.
- For tenant-scoped reads, the relation should resolve the tenant from `where_values_hash` when possible.
- For bulk writes, prefer shifting invalidation to the tenant(s) present in the payload or relation filters.
- If tenant resolution is impossible, fall back to a model-wide version bump, not a silent wrong invalidation.

### Model convention

- Models opt into caching with `has_smart_cache`.
- The model callback module is included in `ApplicationRecord` via `include SmartCacheTenant::ModelCallbacks`.
- After commit, version bumps happen only for models that have `has_smart_cache` enabled.

## Coding conventions

- Keep Ruby style consistent with the codebase: lowercase modules, `# frozen_string_literal: true`, no trailing comments unless required, simple defensive checks, and direct Ruby idioms.
- Use `Rails.cache` rather than introducing external caching libraries or ad hoc storage.
- Do not add generic Rails patterns that do not exist in this project. Keep the code aligned with the gem’s own API and architecture.
- Preserve existing method names such as `smart_cache_enabled?`, `smart_cache_key`, `bump!`, `current`, `has_smart_cache`, and `smart_cache_bump!` unless a broader refactor is explicitly required.
- Prefer small, local changes over broad rewrites.

## Testing and validation

- Tests live under `spec/` and use RSpec.
- The test harness boots a minimal Rails app and uses an in-memory SQLite database in `spec/spec_helper.rb`.
- Common test patterns in this project:
  - clear `Rails.cache` in `before` hooks;
  - create records with explicit `tenant_id` values;
  - validate both tenant-scoped and cross-tenant invalidation;
  - verify that cached reads return fresh values after version bumps.
- Use the project’s real validation command:

```bash
bundle exec rspec
```

- For fresh setup, the README documents:

```bash
bin/setup
```

## Development workflow

- Investigate existing behavior before changing it. The gem is small but the invalidation semantics are subtle.
- Reuse the existing version-store and relation extension patterns rather than introducing a different invalidation model.
- Do not assume every model should be cache-enabled. Only use `has_smart_cache` where the model participates in tenant-aware caching.
- Keep cache writes and invalidations compatible with ActiveRecord relation semantics, especially for `load`, `count`, `sum`, `exists?`, and bulk writes.
- Preserve scope: avoid unrelated refactors, dependency churn, or generic “best practice” changes.

## Restrictions

- Do not replace the version-based invalidation model with direct `Rails.cache.delete` key management.
- Do not broaden the cache to non-ActiveRecord objects unless the repository already demonstrates that pattern.
- Do not add application-level assumptions such as a specific tenant object model or multi-db conventions beyond the configured `tenant_column`.
- Do not create new project-wide conventions without evidence from the codebase.
