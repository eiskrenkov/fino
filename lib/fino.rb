# frozen_string_literal: true

require "forwardable"
require "zeitwerk"

module Fino
  module Configurable
    def configure(&)
      configuration.instance_eval(&)
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
                   :setting

    module_function

    def library
      raise NotImplementedError
    end
  end

  extend Configurable
  extend SettingsAccessible

  module_function

  def library
    Thread.current[:fino_library] ||= Fino::Library.new(configuration)
  end

  def registry
    Thread.current[:fino_registry] ||= Fino::Registry.new
  end

  def root
    File.expand_path("..", __dir__)
  end
end

Zeitwerk::Loader.for_gem.tap do |l|
  root_relative_path = ->(path) { File.join(Fino.root, path) }

  l.ignore(
    [
      root_relative_path.call("lib/fino-ui.rb"),
      root_relative_path.call("lib/fino/ui.rb"),
      root_relative_path.call("lib/fino/ui/"),

      root_relative_path.call("lib/fino-redis.rb"),
      root_relative_path.call("lib/fino/redis.rb"),
      root_relative_path.call("lib/fino/redis/"),

      root_relative_path.call("lib/fino/engine.rb")
    ]
  )
end.setup

require "fino/engine" if defined?(Rails)
