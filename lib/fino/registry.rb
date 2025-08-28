# frozen_string_literal: true

class Fino::Registry
  def initialize(setting_definitions = Hash.new { |h, k| h[k] = {} })
    @setting_definitions = setting_definitions
  end

  def fetch(setting_name, section_name)
    if section_name
      @setting_definitions.dig(section_name, setting_name)
    else
      @setting_definitions[setting_name]
    end
  end

  def settings
    @setting_definitions
  end

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

  def register(setting_definition)
    if setting_definition.section_name
      @setting_definitions[setting_definition.section_name][setting_definition.setting_name] = setting_definition
    else
      @setting_definitions[setting_definition.setting_name] = setting_definition
    end
  end
end
