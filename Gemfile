# frozen_string_literal: true

source "https://rubygems.org"

gemspec name: "fino"

Dir["fino-*.gemspec"].each do |file_name|
  sub_gem_name = File.basename(file_name.split("-").last, File.extname(file_name))

  gemspec name: "fino-#{sub_gem_name}",
          development_group: sub_gem_name
end

# Dummy app live reload
gem "guard-livereload"
gem "rack-livereload"

gem "puma"
gem "rails", "~> #{ENV.fetch('RAILS_VERSION', '8.0')}"

# Database adapters
gem "mysql2", "~> #{ENV.fetch('MYSQL2_VERSION', '0')}"
gem "pg", "~> #{ENV.fetch('POSTGRESQL_VERSION', '1')}"
gem "sqlite3", "~> #{ENV.fetch('SQLITE3_VERSION', '2')}"
gem "trilogy", "~> #{ENV.fetch('TRILOGY_VERSION', '2')}"

gem "rspec", "~> 3.0"
gem "rubocop", "~> 1.80.1", require: false

gem "ruby_llm", "~> 1.14"
