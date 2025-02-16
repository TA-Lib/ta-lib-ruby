# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-01-21

### Added
- Added Zeitwerk inflector configuration for proper constant loading

### Changed
- Renamed module from `TALib` to `TALibFFI` for better clarity
- Renamed main file from `lib/ta_lib.rb` to `lib/ta_lib_ffi.rb`
- Updated require statements in specs and gemspec

## [0.1.0] - 2025-01-21

### Added
- Initial release of ta_lib_ffi
- Basic FFI wrapper for TA-Lib
- Cross-platform support:
  - Windows (64-bit)
  - macOS (via Homebrew)
  - Linux (Debian/Ubuntu packages)
- Automated tests with GitHub Actions
- Basic documentation and usage examples

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Security
- N/A

[0.2.0]: https://github.com/TA-Lib/ta-lib-ruby/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/TA-Lib/ta-lib-ruby/releases/tag/v0.1.0
