# frozen_string_literal: true

require_relative "lib/fino/version"
require_relative "lib/fino/metadata"

Gem::Specification.new do |spec|
  spec.name     = "fino-ui"
  spec.version  = Fino::VERSION

  spec.authors  = ["Egor Iskrenkov"]
  spec.email    = ["egor@iskrenkov.me"]

  spec.summary  = "UI for Fino settings engine"
  spec.homepage = "https://github.com/eiskrenkov/fino"
  spec.license  = "MIT"

  spec.required_ruby_version = Fino::REQUIRED_RUBY_VERSION

  Fino.metadata(spec)

  spec.require_paths = ["lib"]
  spec.files = Dir[
    "README.md",
    "lib/fino/version.rb",
    "lib/fino/ui/**/*"
  ]

  spec.add_dependency "fino", "~> #{Fino::VERSION}"
end
