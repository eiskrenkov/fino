# frozen_string_literal: true




module Fino::Settings::Definition
  def initialize(key, section)
  end

  def value

  end
end

class Fino::Settings::Definition::String
  include Fino::Settings::Definition
end

module Fino::Adapters::Redis
  def read_multi(settings)
    rails.hmget()
  end
end

class Fino::Adapters::Solid
end

class Configuration
  attr_accessor :adapter

  def initialize
    @adapter = nil
  end
end

Fino::Adapters::Composition.new(
  Fino::Cache::Memory.new,
  Fino::Memoization.new,
  Fino::Adapters::Redis.new,
)

class Fino::Registry
  def initialize(setting_definitions)
    @setting_definitions
  end

  def fetch(setting_name, section_name)
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

      def setting(setting_name, options = {})
        registry.register(SettingDefinition.new(setting_name, section_name, options))
      end
    end

    def initialize(registry)
      @registry = registry
    end

    def setting(setting_name, options = {})
      registry.register(SettingDefinition.new(setting_name, nil, options))
    end

    def section(section_name, options = {})
      SectionDSL.new(section_name, options, registry)
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
  def library
    Thread.current[:fino_library] ||= Library.new
  end

  def settings(&)
    settings_registry.instance_eval(&)
  end

  def setting(setting_name, section_name)
    library.read(setting_name.to_s, section_name.to_s)
  end
end
