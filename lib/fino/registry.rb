# frozen_string_literal: true

class Fino::Registry
  class DSL
    class SectionDSL
      def initialize(section_definition, registry)
        @section_definition = section_definition
        @registry = registry
      end

      def setting(setting_name, type, **)
        @registry.register(
          Fino::Definition::Setting.new(
            type: type,
            setting_name: setting_name,
            section_definition: @section_definition,
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
        Fino::Definition::Setting.new(
          type: type,
          setting_name: setting_name,
          **
        )
      )
    end

    def section(section_name, options = {}, &)
      section_definition = Fino::Definition::Section.new(
        name: section_name,
        **options
      )

      @registry.register_section(section_definition)

      SectionDSL.new(section_definition, @registry).instance_eval(&)
    end
  end

  UnknownSetting = Class.new(Fino::Error)

  using Fino::Ext::Hash

  attr_reader :setting_definitions, :section_definitions

  def initialize
    @setting_definitions = []
    @setting_definitions_by_path = {}

    @section_definitions = []
    @section_definitions_by_name = {}
  end

  def setting_definition(*path)
    @setting_definitions_by_path.dig(*path.compact.reverse).tap do |definition|
      raise UnknownSetting, "Unknown setting: #{path.compact.join('.')}" unless definition
    end
  end

  def setting_definitions(at: Fino::EMPTINESS)
    case at
    when Fino::EMPTINESS
      @setting_definitions
    when nil
      @setting_definitions.select { |d| d.section_definition.nil? }
    else
      @setting_definitions_by_path[at&.to_s]&.values || []
    end
  end

  def section_definition(section_name)
    @section_definitions_by_name[section_name.to_s]
  end

  def register(setting_definition)
    @setting_definitions << setting_definition

    @setting_definitions_by_path.deep_set(setting_definition, *setting_definition.path.map(&:to_s))
  end

  def register_section(section_definition)
    @section_definitions << section_definition
    @section_definitions_by_name.deep_set(section_definition, section_definition.name.to_s)
  end
end
