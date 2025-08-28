# frozen_string_literal: true

require_relative "lib/fino/version"

Gem::Specification.new do |spec|
  spec.name     = "fino"
  spec.version  = Fino::VERSION

  spec.authors  = ["Egor Iskrenkov"]
  spec.email    = ["egor@iskrenkov.me"]

  spec.summary  = "Active Config"
  spec.homepage = "https://github.com/eiskrenkov/active_config"

  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = Dir["README.md", "lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "zeitwerk", "~> 2.5"
end
