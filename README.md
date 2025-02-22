# TALibFFI

![Tests](https://github.com/TA-Lib/ta-lib-ruby/actions/workflows/main.yml/badge.svg)
[![Gem Version](https://badge.fury.io/rb/ta_lib_ffi.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/ta_lib_ffi)

## Introduction

TALibFFI is a Ruby binding for [TA-Lib](https://ta-lib.org/) (Technical Analysis Library) using FFI (Foreign Function Interface). It provides a comprehensive set of functions for technical analysis of financial market data. This gem is based on the [TA-Lib C headers](https://github.com/TA-Lib/ta-lib/blob/6a07e4ca1877c5ab4b08b81015858bfcbf2ef832/include/ta_abstract.h#L45), providing a Ruby-friendly interface to the underlying C library.

## Requirements

- Ruby >= 3.1.0
- TA-Lib >= 0.6.4

## Installation

### [Install TA-Lib](https://ta-lib.org/install/)

#### Windows
Download and run the installer: [ta-lib-0.6.4-windows-x86_64.msi](https://github.com/ta-lib/ta-lib/releases/download/v0.6.4/ta-lib-0.6.4-windows-x86_64.msi)

#### macOS
```bash
brew install ta-lib
```

#### Linux (Debian/Ubuntu)
```bash
# For Intel/AMD 64-bit
wget https://github.com/ta-lib/ta-lib/releases/download/v0.6.4/ta-lib_0.6.4_amd64.deb
sudo dpkg -i ta-lib_0.6.4_amd64.deb

# For ARM64
wget https://github.com/ta-lib/ta-lib/releases/download/v0.6.4/ta-lib_0.6.4_arm64.deb
sudo dpkg -i ta-lib_0.6.4_arm64.deb

# For Intel/AMD 32-bits
wget https://github.com/ta-lib/ta-lib/releases/download/v0.6.4/ta-lib_0.6.4_i386.deb
sudo dpkg -i ta-lib_0.6.4_i386.deb
```

### [Installing the Ruby Gem](https://rubygems.org/gems/ta_lib_ffi)

Add this to your application's Gemfile:

```ruby
gem 'ta_lib_ffi'
```

Then execute:

    $ bundle install

Or install it directly:

    $ gem install ta_lib_ffi

## Usage

```ruby
require 'ta_lib_ffi'

# Initialize data
prices = [10.0, 11.0, 12.0, 11.0, 10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0]

# Calculate SMA
puts TALibFFI.sma(prices, time_period: 3)
# => [11.0, 11.333333333333334, 11.0, 10.0, 9.0, 8.0, 7.0, 6.0, 5.0]

# Average True Range (ATR) Example
high = [82.15, 81.89, 83.03, 83.30, 83.85, 83.90, 83.33, 84.30, 84.84, 85.00, 85.90, 86.58, 86.98, 88.00, 87.87]
low  = [81.29, 80.64, 81.31, 82.65, 83.07, 83.11, 82.49, 82.30, 84.15, 84.11, 84.03, 85.39, 85.76, 87.17, 87.01]
close = [81.59, 81.06, 82.87, 83.00, 83.61, 83.15, 82.84, 83.99, 84.55, 84.36, 85.53, 86.54, 86.89, 87.77, 87.29]

# Calculate ATR with period = 5
result = TALibFFI.atr([high, low, close], time_period: 5)
# => [1.101999999999998, 1.0495999999999992, 1.2396799999999994, 1.1617440000000012, 1.1073952000000011, ...]
```

## Documentation
- [API Documentation](https://www.rubydoc.info/github/TA-Lib/ta-lib-ruby/main) - Detailed documentation of all available methods and classes

## TODO
- [ ] Add RDoc documentation for Ruby methods
- [ ] Create detailed function examples with input/output samples
- [ ] Add more tests for each function
- [ ] Support custom TA-Lib installation location

## Development

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TA-Lib/ta-lib-ruby

## License

This gem is available as open source under the terms of the [MIT License](LICENSE).
