# frozen_string_literal: true

class Fino::Registry
  class DSL
    class SectionDSL
      def initialize(section_name, options, registry)
        @section_name = section_name
        @registry = registry
      end

      def setting(setting_name, type, **)
        @registry.register(
          Fino::SettingDefinition.new(
            type: type,
            setting_name: setting_name,
            section_name: @section_name,
            **
          )
        )
      end
    end

    def initialize(registry)
      @registry = registry
    end

    def setting(setting_name, type, **)
      @registry.register(
        Fino::SettingDefinition.new(
          type: type,
          setting_name: setting_name,
          **
        )
      )
    end

    def section(section_name, options = {}, &)
      SectionDSL.new(section_name, options, @registry).instance_eval(&)
    end
  end

  UnknownSetting = Class.new(Fino::Error)

  using Fino::Ext::Hash

  attr_reader :setting_definitions_by_path, :setting_definitions

  def initialize
    @setting_definitions_by_path = {}
    @setting_definitions = []
  end

  def fetch(*path)
    @setting_definitions_by_path.dig(*path).tap do |definition|
      raise UnknownSetting, "Unknown setting: #{path.compact.join('.')}" unless definition
    end
  end

  def register(setting_definition)
    @setting_definitions << setting_definition

    @setting_definitions_by_path.deep_set(setting_definition, *setting_definition.path)
  end
end
