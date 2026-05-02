## [Unreleased]

## [0.3.0] - 2026-05-02

- Fixed tenant version invalidation path in `VersionStore.bump!` when `tenant_column` is configured and `tenant_id` is blank.
- Added wildcard invalidation behavior to clear tenant-scoped version keys on global bulk invalidation scenarios.
- Added Rails 7 runtime dependency declaration in the gemspec.
- Added a development bootstrap for `bin/console` with a minimal Rails + ActiveRecord environment.
- Added a complete RSpec suite covering cached reads, version store behavior, `after_commit` invalidation, and bulk write invalidation (`insert_all`, `upsert_all`, `update_all`).

## [0.2.0] - 2026-05-01

- Added all features and improvements for the first major release.

## [0.1.0] - 2026-05-01

- Initial release
