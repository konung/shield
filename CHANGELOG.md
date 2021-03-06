# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2020-08-29

### Added
- Add email confirmation
- Add support for return URL (a session value to redirect back to)

### Changed
- Introduce `Shield::Session` as base type for all session wrappers
- Improve previous page determination
- Rename `*_hash` columns to `*_digest`.

### Fixed
- Fix `#redirect_back` redirecting to login page
- Fix invalid HTTP date format for "Expires" header in `#disable_cache` action pipe

## [0.1.0] - 2020-08-15

### Added
- Initial public release
