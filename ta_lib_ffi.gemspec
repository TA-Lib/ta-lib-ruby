# frozen_string_literal: true

require_relative "lib/ta_lib_ffi"

Gem::Specification.new do |spec|
  spec.name = "ta_lib_ffi"
  spec.version = TALibFFI::VERSION
  spec.authors = ["Victor Yang"]
  spec.email = ["victor@rt4u.bid"]
  spec.summary = "Ruby FFI bindings for TA-Lib (Technical Analysis Library)"
  spec.description = "A Ruby wrapper for TA-Lib using FFI, providing technical analysis functions for financial market data"
  spec.homepage = "https://github.com/TA-Lib/ta-lib-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/TA-Lib/ta-lib-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/TA-Lib/ta-lib-ruby/blob/main/CHANGELOG.md"
  spec.files = Dir[
    "lib/**/*",
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md",
    "Gemfile",
    "Rakefile",
    "ta_lib_ffi.gemspec",
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "fiddle", "~> 1.1"
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop-rspec", "~> 3.3"
  spec.add_development_dependency "ruby-lsp-rspec", "~> 0.1.20"
  spec.add_development_dependency "webrick", "~> 1.9"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
