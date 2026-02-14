# frozen_string_literal: true

require "forwardable"
require "zeitwerk"

# Fino is a dynamic settings engine for Ruby and Rails.
#
# It provides a DSL for defining typed settings (string, integer, float, boolean),
# organized into optional sections, with support for scoped overrides, A/B testing
# variants, and unit conversion for numeric values.
#
# All settings access methods are delegated to Fino::Library, making the +Fino+
# module the primary public interface.
#
# == Quick Start
#
#   require "fino-redis"
#
#   Fino.configure do
#     adapter { Fino::Redis::Adapter.new(Redis.new) }
#     cache { Fino::Cache::Memory.new(expires_in: 3) }
#
#     settings do
#       setting :maintenance_mode, :boolean, default: false
#
#       section :openai, label: "OpenAI" do
#         setting :model, :string, default: "gpt-5"
#         setting :temperature, :float, default: 0.7
#       end
#     end
#   end
#
#   Fino.value(:model, at: :openai)        #=> "gpt-5"
#   Fino.enabled?(:maintenance_mode)       #=> false
#   Fino.set(model: "gpt-6", at: :openai)
#
# == Architecture
#
# Fino uses a pipeline architecture with composable pipes for reading and writing
# settings. A storage adapter (e.g. Redis) persists values, and an optional cache
# layer reduces round-trips. See Fino::Pipeline, Fino::Adapter, and Fino::Cache.
module Fino
  # Manages lifecycle of Fino's core objects (library, registry, configuration).
  #
  # Extended into the Fino module to provide top-level +configure+, +reset!+,
  # and +reconfigure+ methods.
  module Stateful
    # Evaluates the given block in the context of Fino::Configuration.
    #
    # This is the primary entry point for setting up Fino. The block receives
    # the configuration DSL including +adapter+, +cache+, +settings+, and +pipeline+.
    #
    #   Fino.configure do
    #     adapter { MyAdapter.new }
    #     settings do
    #       setting :timeout, :integer, default: 30
    #     end
    #   end
    def configure(&)
      configuration.instance_eval(&)
    end

    # Resets all internal state, discarding the current library, registry,
    # and configuration. Subsequent calls will create fresh instances.
    def reset!
      @library = nil
      @registry = nil
      @configuration = nil
    end

    # Resets all state and re-evaluates the configuration block.
    # Equivalent to calling +reset!+ followed by +configure+.
    def reconfigure(&)
      reset!
      configure(&)
    end

    # Returns the current Fino::Library instance, creating one if needed.
    #
    # The library is the main engine that handles reading and writing settings
    # through the configured pipeline.
    def library
      @library ||= Fino::Library.new(configuration)
    end

    # Returns the current Fino::Registry instance, creating one if needed.
    #
    # The registry holds all setting and section definitions.
    def registry
      @registry ||= Fino::Registry.new
    end

    # Returns the current Fino::Configuration instance, creating one if needed.
    def configuration
      @configuration ||= Fino::Configuration.new(registry)
    end
  end

  # Provides delegated access to Fino::Library settings methods.
  #
  # All public settings operations (+value+, +set+, +enabled?+, etc.) are
  # forwarded to the +library+ instance. Any class or module that includes
  # this module and implements +library+ gains the full settings API.
  #
  # See Fino::Library for detailed documentation of each method.
  module SettingsAccessible
    extend Forwardable

    # @!method value(setting_name, at: nil, **context)
    #   Returns the value of a single setting. See Fino::Library#value.
    # @!method values(*setting_names, at: nil, **context)
    #   Returns values of multiple settings. See Fino::Library#values.
    # @!method enabled?(setting_name, at: nil, **context)
    #   Returns +true+ if a boolean setting is enabled. See Fino::Library#enabled?.
    # @!method disabled?(setting_name, at: nil, **context)
    #   Returns +true+ if a boolean setting is disabled. See Fino::Library#disabled?.
    # @!method enable(setting_name, at: nil, for: nil)
    #   Enables a boolean setting globally or for a scope. See Fino::Library#enable.
    # @!method disable(setting_name, at: nil, for: nil)
    #   Disables a boolean setting globally or for a scope. See Fino::Library#disable.
    # @!method setting(setting_name, at: nil)
    #   Returns a Setting object for a single setting. See Fino::Library#setting.
    # @!method settings(*setting_names, at: nil)
    #   Returns Setting objects for multiple settings. See Fino::Library#settings.
    # @!method slice(*settings)
    #   Preloads specific settings in a single adapter call. See Fino::Library#slice.
    # @!method set(**data)
    #   Persists a setting value with optional overrides and variants. See Fino::Library#set.
    # @!method add_override(setting_name, at: nil, **overrides)
    #   Adds scope overrides to an existing setting. See Fino::Library#add_override.
    def_delegators :library,
                   :value,
                   :values,
                   :enabled?,
                   :disabled?,
                   :enable,
                   :disable,
                   :setting,
                   :settings,
                   :slice,
                   :set,
                   :add_override

    def library
      raise NotImplementedError
    end
  end

  extend SettingsAccessible
  extend Stateful

  # Sentinel object used internally to distinguish "no argument provided"
  # from an explicit +nil+.
  EMPTINESS = Object.new.freeze

  module_function

  # Returns the logger used by Fino for debug and diagnostic output.
  #
  # Defaults to a +Logger+ writing to +$stdout+ at the level specified by
  # the +FINO_LOG_LEVEL+ environment variable (default: +"info"+).
  def logger
    @logger ||= begin
      require "logger"

      Logger.new($stdout).tap do |l|
        l.progname = name
        l.level = ENV.fetch("FINO_LOG_LEVEL", "info")
        l.formatter = proc do |severity, _datetime, progname, msg|
          "[#{progname}] #{severity}: #{msg}\n"
        end
      end
    end
  end

  # Returns the root path of the Fino gem installation.
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

      # Fino Solid
      root_relative_path.call("lib/fino-solid.rb"),
      root_relative_path.call("lib/fino/solid.rb"),
      root_relative_path.call("lib/fino/solid/"),

      # Other
      root_relative_path.call("lib/fino/metadata.rb"),
      root_relative_path.call("lib/fino/railtie.rb")
    ]
  )
end.setup
