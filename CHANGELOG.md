# Changelog

## [1.1.1](https://github.com/Olensys/terraform-google-cloud-armor/compare/v1.1.0...v1.1.1) (2026-10-24)


### Bug Fixes

* run integration on change and weekly instead of nightly ([22d0031](https://github.com/Olensys/terraform-google-cloud-armor/commit/22d00317e88a4b0655fe6b469d8c85d48189c637))

## 1.1.0

### Fixes

- normalise `context.extra_tags` keys and values to valid GCP label syntax (lowercase, invalid characters to `-`, 63 characters); `labels` still win

### Tests

- `test_tags_contract` covers a mixed-case tag key and a value with a space

### Docs

- README usage shows the naming module

### Behaviour changes

- `context.extra_tags` entries now appear as normalised labels (for example `Team = "Core Team"` becomes `team = "core-team"`). Callers that relied on unnormalised keys must read the normalised ones; values that previously failed GCP label validation now succeed.

## 1.0.0

- Cloud Armor security policy with OWASP CRS v33 preconfigured rules, IP allow and deny lists, per-IP rate limiting and Adaptive Protection, wrapping GoogleCloudPlatform/cloud-armor/google 9.0.0.
