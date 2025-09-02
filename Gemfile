# frozen_string_literal: true

source "https://rubygems.org"

gemspec name: "fino"

Dir["fino-*.gemspec"].each do |file_name|
  sub_gem_name = File.basename(file_name.split("-").last, File.extname(file_name))

  gemspec name: "fino-#{sub_gem_name}",
          development_group: sub_gem_name
end

gem "rails", "~> #{ENV['RAILS_VERSION'] || '8.0'}"
gem "puma"
gem 'sqlite3', "~> #{ENV['SQLITE_VERSION'] || '2.7'}"

gem "rubocop", "~> 1.80.1", require: false
