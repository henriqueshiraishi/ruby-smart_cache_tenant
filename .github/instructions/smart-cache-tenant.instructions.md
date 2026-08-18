---
applyTo: "lib/**/*.rb"
---

# SmartCacheTenant library rules

## Objective

Keep the library behavior consistent with the gem’s existing tenant-aware ActiveRecord cache design and its version-based invalidation model.

## Patterns

- `ActiveRecord::Relation` is extended by prepending `SmartCacheTenant::CacheableRelation` via the Railtie.
- `ActiveRecord::Base` persistence hooks are extended by prepending `SmartCacheTenant::CacheablePersistence`.
- Models opt into the cache with `has_smart_cache` and only invalidate when the model is marked as cache-enabled.
- Cache reads are stored in `Rails.cache` using a digest of the generated SQL, tenant, operation, and model version tokens.
- Cache invalidation follows a version-store pattern instead of delete-by-query-key logic.

## Conventions

- Use the same Ruby naming already present in the project: `smart_cache_enabled?`, `smart_cache_key`, `bump!`, `current`, `has_smart_cache`, and `smart_cache_bump!`.
- Keep the public configuration contract as defined in `SmartCacheTenant::Configuration`.
- Preserve compatibility with `Rails.cache` backends and ActiveRecord relation APIs instead of abstracting away the underlying behavior.
- Prefer tenant-aware invalidation for bulk operations when a tenant can be inferred from relation filters or payload attributes.

## Rules

- Do not bypass the version-store mechanism with ad hoc cache deletions.
- Do not treat the cache as active unless `SmartCacheTenant.config.enabled` is true.
- Do not assume all models are cache-enabled; respect `has_smart_cache`.
- Do not broaden the cache contract to non-ActiveRecord objects unless there is explicit repository precedent for that behavior.
- Preserve the current fallback behavior: when tenant resolution is not available, use a broader model-level bump instead of incorrect tenant-specific invalidation.

## Restrictions

- Do not add new framework dependencies or generic cache abstraction layers.
- Do not rewrite the gem around a different invalidation design.
- Do not create app-level assumptions like explicit tenant object classes or tenant-aware service layers inside this library.
- Do not add code paths that silently ignore `tenant_column` when the relation is tenant-scoped.

## Tests

- Tests for new behavior should live under `spec/` and follow the patterns already used in the project.
- Validate tenant-scoped reads and invalidation, especially where a write affects only one tenant or the whole model.
- Cover bulk writes (`insert_all`, `upsert_all`, `update_all`) when touching that area.
- Use clear `Rails.cache.clear` setup in test examples to avoid leaking version state.

## Example references

This project already follows the pattern below:

- `SmartCacheTenant::VersionStore.build_key` builds a tenant-scoped or model-wide key.
- `SmartCacheTenant::ModelCallbacks` invalidates after commit.
- `SmartCacheTenant::CacheableRelation#load`, `#calculate`, and `#exists?` cache relation results.
