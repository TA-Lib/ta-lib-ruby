# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-11-23

### Added

- Support for the TA-Lib 0.8.3 function metadata layout and indicators, including ALMA, alongside 0.6.4. Set `TA_LIB_PATH` to select a particular shared library.
- Direct C comparisons for the indicators in each installed library and CI coverage for the latest stable Ruby 4.x.

### Fixed

- Fixed HTML documentation generation on Ruby 4. The local API reference includes the indicators and defaults from the selected TA-Lib C library.
- Fixed unbounded memory growth during repeated indicator calls. Numeric arrays are packed in bulk, and Ruby owns the input and output buffers for the duration of each call.
- Invalid input counts, incorrectly grouped price fields, unequal lengths and unknown keywords raise `TALibFFI::TALibError` with details. Previously unknown keywords silently used the default.

Indicator defaults and results follow the installed TA-Lib version. This includes the BBANDS default period and how MINMAXINDEX selects among equal extrema.

## [0.3.0] - 2025-02-23

### Added
- Auto-generated YARD documentation
- GitHub Actions PR Agent workflow
- Cross-platform test support (Ubuntu, macOS, Windows)

### Changed
- Optimized function documentation generator
- Improved error handling and validation
- Updated development dependencies

### Fixed
- Fixed prices handling in multiple technical analysis functions

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

[0.4.0]: https://github.com/TA-Lib/ta-lib-ruby/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/TA-Lib/ta-lib-ruby/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/TA-Lib/ta-lib-ruby/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/TA-Lib/ta-lib-ruby/releases/tag/v0.1.0
