# TALibFFI

![Tests](https://github.com/TA-Lib/ta-lib-ruby/actions/workflows/main.yml/badge.svg)

## Introduction

TALibFFI is a Ruby binding for [TA-Lib](https://ta-lib.org/) (Technical Analysis Library) using FFI (Foreign Function Interface). It provides a comprehensive set of functions for technical analysis of financial market data.

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

### Installing the Ruby Gem

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
```

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
