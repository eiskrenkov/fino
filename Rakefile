#!/usr/bin/env rake
# frozen_string_literal: true

require "fino/version"
require "rdoc/task"

ARTIFACTS_FOLDER = "artifacts"

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "doc"
  rdoc.title = "Fino #{Fino::VERSION}"
  rdoc.main = "README.md"
  rdoc.rdoc_files.include("README.md", "lib/**/*.rb")
  rdoc.rdoc_files.exclude(
    "lib/fino-rails.rb",
    "lib/fino-redis.rb",
    "lib/fino-solid.rb",
    "lib/fino/rails.rb",
    "lib/fino/rails/**/*",
    "lib/fino/redis.rb",
    "lib/fino/redis/**/*",
    "lib/fino/solid.rb",
    "lib/fino/solid/**/*",
    "lib/fino/metadata.rb",
    "lib/fino/railtie.rb"
  )
end

desc "Build all gems into the artifacts directory"
task :build do
  FileUtils.rm_rf(ARTIFACTS_FOLDER)

  Dir["*.gemspec"].each do |gemspec|
    sh "gem", "build", gemspec
  end

  FileUtils.mkdir_p(ARTIFACTS_FOLDER)
  FileUtils.mv(Dir["*.gem"], ARTIFACTS_FOLDER)
end

desc "Tags version, pushes to remote, and pushes gem"
task release: :build do
  sh "git push origin master"

  sh "git", "tag", "v#{Fino::VERSION}"
  sh "git push origin v#{Fino::VERSION}"

  print "\nOTP: "
  otp = $stdin.gets.chomp

  sh "ls #{ARTIFACTS_FOLDER}/*.gem | xargs -n 1 gem push --otp #{otp}"
end
