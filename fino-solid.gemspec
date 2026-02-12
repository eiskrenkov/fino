# frozen_string_literal: true

require_relative "lib/fino/version"
require_relative "lib/fino/metadata"

Gem::Specification.new do |spec|
  spec.name     = "fino-solid"
  spec.version  = Fino::VERSION

  spec.authors  = ["Egor Iskrenkov"]
  spec.email    = ["egor@iskrenkov.me"]

  spec.summary  = "ActiveRecord adapter for Fino settings engine"
  spec.homepage = "https://github.com/eiskrenkov/fino"
  spec.license  = "MIT"

  spec.required_ruby_version = Fino::REQUIRED_RUBY_VERSION

  Fino.metadata(spec)

  spec.require_paths = ["lib"]
  spec.files = Dir[
    "README.md",
    "LICENSE",
    "lib/fino/version.rb",
    "lib/fino-solid.rb",
    "lib/fino/solid.rb",
    "lib/fino/solid/**/*"
  ]

  spec.add_dependency "activerecord", ">= 6.1"
  spec.add_dependency "fino", "~> #{Fino::VERSION}"

  spec.add_development_dependency "mysql2", ">= 0.5"
  spec.add_development_dependency "pg", ">= 1.0"
  spec.add_development_dependency "sqlite3", ">= 1.4"
end
