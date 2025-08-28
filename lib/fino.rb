# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Fino::Settings::Definition
  def initialize(key, section)
  end

  def value

  end
end

class Fino::Settings::Definition::String
  include Fino::Settings::Definition
end

class Fino::Adapters::Solid
end

class Configuration
  attr_accessor :adapter

  def initialize
    @adapter = nil
  end
end

# Fino::Adapters::Composition.new(
#   Fino::Cache::Memory.new,
#   Fino::Memoization.new,
#   Fino::Adapters::Redis.new,
# )

class Fino::Registry
  def initialize(setting_definitions = {})
    @setting_definitions = setting_definitions
  end

  def fetch(se  tting_name, section_name)
    if section_name
      @setting_definitions.dig(section_name, setting_name)
    else
      @setting_definitions[setting_name]
    end
  end

  class DSL
    class SectionDSL
      def initialize(section_name, options, registry)
        @section_name = section_name
        @registry = registry
      end

      def setting(setting_name, type, options = {})
        @registry.register(Fino::SettingDefinition.new(setting_name, section_name, type, options))
      end
    end

    def initialize(registry)
      @registry = registry
    end

    def setting(setting_name, type, options = {})
      @registry.register(Fino::SettingDefinition.new(setting_name, nil, type, options))
    end

    def section(section_name, options = {})
      SectionDSL.new(section_name, options, @registry)
    end
  end

  def register(setting_definition)
    if setting_definition.section_name
      @setting_definitions[setting_definition.section_name][setting_definition.setting_name] = setting_definition
    else
      @setting_definitions[setting_definition.setting_name] = setting_definition
    end
  end
end

module Fino
  extend self

  def library
    Thread.current[:fino_library] ||= Fino::Library.new
  end

  def settings(&)
    section_dsl.instance_eval(&)
  end

  def section_dsl
    @section_dsl = Fino::Registry::DSL.new(settings_registry)
  end

  def settings_registry
    @settings_registry ||= Fino::Registry.new
  end

  def setting(setting_name, section_name)
    library.read(setting_name.to_s, section_name.to_s)
  end
end
