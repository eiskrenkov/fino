# frozen_string_literal: true

require "forwardable"
require "zeitwerk"

module Fino
  module Configurable
    def configure(&block)
      configuration.instance_eval(&block)
    end

    private

    def configuration
      @configuration ||= Fino::Configuration.new(registry)
    end
  end

  module SettingsAccessible
    extend Forwardable

    def_delegators :library,
                   :value,
                   :values,
                   :setting,
                   :settings,
                   :all,
                   :set

    module_function

    def library
      raise NotImplementedError
    end
  end

  extend Configurable
  extend SettingsAccessible

  EMPTINESS = Object.new.freeze

  module_function

  def library
    Thread.current[:fino_library] ||= Fino::Library.new(configuration)
  end

  def registry
    @registry ||= Fino::Registry.new
  end

  def logger
    @logger ||= begin
      require "logger"

      Logger.new($stdout).tap do |l|
        l.progname = name
        l.level = ENV.fetch("FINO_LOG_LEVEL", "info")
        l.formatter = proc do |severity, datetime, progname, msg|
          "[#{progname}] #{severity}: #{msg}\n"
        end
      end
    end
  end

  def root
    File.expand_path("..", __dir__)
  end
end

Zeitwerk::Loader.for_gem.tap do |l|
  root_relative_path = ->(path) { File.join(Fino.root, path) }

  l.ignore(
    [
      # Fino Rails
      root_relative_path.call("lib/fino-rails.rb"),
      root_relative_path.call("lib/fino/rails.rb"),
      root_relative_path.call("lib/fino/rails/"),

      # Fino Redis
      root_relative_path.call("lib/fino-redis.rb"),
      root_relative_path.call("lib/fino/redis.rb"),
      root_relative_path.call("lib/fino/redis/"),

      # Other
      root_relative_path.call("lib/fino/metadata.rb"),
      root_relative_path.call("lib/fino/railtie.rb")
    ]
  )
end.setup
