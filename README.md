# TALibFFI

[![Tests](https://github.com/TA-Lib/ta-lib-ruby/actions/workflows/main.yml/badge.svg)](https://github.com/TA-Lib/ta-lib-ruby/actions/workflows/main.yml)
[![Gem version](https://badge.fury.io/rb/ta_lib_ffi.svg)](https://rubygems.org/gems/ta_lib_ffi)

`ta_lib_ffi` exposes the technical indicators in your installed TA-Lib C library as Ruby methods. A three-period simple moving average returns its first value at the third price.

```ruby
require "ta_lib_ffi"

close = [10, 11, 12, 13, 14]
TALibFFI.sma(close, time_period: 3)
# => [11.0, 12.0, 13.0]
```

## Installation

You need Ruby 3.1 or later and the TA-Lib C shared library 0.6.4 or later. If you already use C library 0.6.4, you can keep it when upgrading the gem to 0.4.0.

- **macOS** — Run `brew install ta-lib`.
- **Debian or Ubuntu** — Download the `.deb` matching `dpkg --print-architecture`. For example, on `amd64`, install the downloaded file with `sudo dpkg -i ./ta-lib_0.8.3_amd64.deb`. [Debian packages](https://ta-lib.org/install/c/#linux-debian-packages)
- **Windows x64** — Run the [TA-Lib 0.8.3 x64 installer](https://github.com/TA-Lib/ta-lib/releases/download/v0.8.3/ta-lib-0.8.3-windows-x86_64.msi).

For a custom installation, set `TA_LIB_PATH` to the full path of the shared library (`.so`, `.dylib` or `.dll`) before requiring the gem. [TA-Lib installation guide](https://ta-lib.org/install/c/)

Add the gem to your application with `bundle add ta_lib_ffi`, or install it directly with `gem install ta_lib_ffi`.

## Inputs and results

Pass price fields together in the order the indicator expects. For Average True Range (ATR), pass high, low and close as one argument. All input series must be nonempty and have the same length.

```ruby
high  = [11, 13, 12, 14, 15]
low   = [9, 10, 9, 11, 12]
close = [10, 12, 10, 13, 14]

TALibFFI.atr([high, low, close], time_period: 2)
# => [3.0, 3.5, 3.25]
```

Single-output indicators return an array. Indicators with several outputs return a hash of arrays keyed by output name. Each array starts at the first input position for which the indicator has enough history.

```ruby
TALibFFI.minmax([12, 10, 14, 11, 13], time_period: 3)
# => { min: [10.0, 10.0, 11.0], max: [14.0, 14.0, 14.0] }
```

## C library compatibility

The loaded C library determines which methods are available and their default parameters. CI tests Ruby 3.1 through the latest stable Ruby 4.x across Linux, macOS and Windows with TA-Lib C 0.6.4 and 0.8.3.

| TA-Lib C | Indicators | Default BBANDS period | ALMA available |
| --- | ---: | ---: | --- |
| 0.6.4 | 161 | 5 | No |
| 0.7.1 | 161 | 5 | No |
| 0.8.1 | 201 | 20 | No |
| 0.8.3 | 237 | 20 | Yes |

Pass `time_period:` explicitly to use the same BBANDS window across versions. Use `respond_to?` when calling an indicator that some installations may lack, such as the Arnaud Legoux Moving Average (ALMA), or inspect `TALibFFI.group_table` and `TALibFFI.function_table(group)` to list loaded indicators.

```ruby
if TALibFFI.respond_to?(:alma)
  prices = (1..8).map(&:to_f)
  TALibFFI.alma(prices, time_period: 4, sigma: 4.0, offset: 0.75).map { |value| value.round(4) }
  # => [2.8847, 3.8847, 4.8847, 5.8847, 6.8847]
end
```

When upgrading to gem 0.4.0, check your keyword arguments. A misspelling such as `timeperiod:` now raises `TALibFFI::TALibError` and the error lists the accepted keywords. [Changelog](CHANGELOG.md)

## API documentation

The gem ships method signatures generated with TA-Lib C 0.8.3. [API reference for gem 0.4.0](https://gemdocs.org/gems/ta_lib_ffi/0.4.0/TALibFFI.html)

For an offline copy, run `bundle install` and `bundle exec yard doc` from the release checkout, then open `doc/TALibFFI.html`. To regenerate the reference from your installed C library, run `bundle exec rake yard`. That task also updates the generated method comments in `lib/ta_lib_ffi.rb`. Use TA-Lib C 0.8.3 when refreshing the signatures for this release.

## Development

From a checkout, run `bundle install` followed by `bundle exec rake` to run RSpec and RuboCop. To run just the C comparison tests, use `bundle exec rspec spec/ta_lib_ffi_c_reference_spec.rb`. They call each indicator through Ruby and directly through the installed C library with the same inputs, then compare output values, types, lengths and keys.

Bug reports and pull requests are welcome. [GitHub repository](https://github.com/TA-Lib/ta-lib-ruby)

## License

[MIT License](LICENSE.txt)
