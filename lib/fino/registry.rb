# frozen_string_literal: true

class Fino::Registry
  class DSL
    class SectionDSL
      def initialize(section_name, options, registry)
        @section_name = section_name
        @registry = registry
      end

      def setting(setting_name, type, options = {})
        @registry.register(Fino::SettingDefinition.new(setting_name, @section_name, type, options))
      end
    end

    def initialize(registry)
      @registry = registry
    end

    def setting(setting_name, type, options = {})
      @registry.register(Fino::SettingDefinition.new(setting_name, nil, type, options))
    end

    def section(section_name, options = {}, &)
      SectionDSL.new(section_name, options, @registry).instance_eval(&)
    end
  end

  UnknownSetting = Class.new(Fino::Error)

  attr_reader :setting_definitions_by_path, :setting_definitions

  def initialize
    @setting_definitions_by_path = Hash.new { |h, k| h[k] = {} }
    @setting_definitions = []
  end

  def fetch(setting_name, section_name)
    definition =
      if section_name
        @setting_definitions_by_path.dig(section_name, setting_name)
      else
        @setting_definitions_by_path[setting_name]
      end

    raise UnknownSetting, "Unknown setting: #{[section_name, setting_name].compact.join('.')}" unless definition

    definition
  end

  def register(setting_definition)
    @setting_definitions << setting_definition

    if setting_definition.section_name
      @setting_definitions_by_path[setting_definition.section_name][setting_definition.setting_name] = setting_definition
    else
      @setting_definitions_by_path[setting_definition.setting_name] = setting_definition
    end
  end
end
