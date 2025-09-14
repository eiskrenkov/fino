# frozen_string_literal: true

require_relative "lib/fino/version"
require_relative "lib/fino/metadata"

SUBGEMS_FILES = [
  # Fino Redis
  "lib/fino/redis.rb",
  "lib/fino/redis/**/*",

  # Fino Rails
  "lib/fino/rails.rb",
  "lib/fino/rails/**/*"
].freeze

Gem::Specification.new do |spec|
  spec.name     = "fino"
  spec.version  = Fino::VERSION

  spec.authors  = ["Egor Iskrenkov"]
  spec.email    = ["egor@iskrenkov.me"]

  spec.summary  = "Elegant & performant settings engine for Ruby and Rails"
  spec.homepage = "https://github.com/eiskrenkov/fino"
  spec.license  = "MIT"

  spec.required_ruby_version = Fino::REQUIRED_RUBY_VERSION

  Fino.metadata(spec)

  spec.require_paths = ["lib"]
  spec.files = Dir[
    "README.md",
    "lib/**/*.rb",
  ] - Dir[*SUBGEMS_FILES]

  spec.add_dependency "zeitwerk", "~> 2.5"
end
