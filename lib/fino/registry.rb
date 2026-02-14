# frozen_string_literal: true

# Stores and indexes all setting and section definitions.
#
# The registry is populated during Fino.configure via the DSL and provides
# lookup methods used by Fino::Library to resolve setting names to their
# definitions.
class Fino::Registry
  # Raised when attempting to register a setting that already exists at the
  # same path.
  DuplicateSetting = Class.new(Fino::Error)

  # Raised when looking up a setting that has not been registered.
  UnknownSetting = Class.new(Fino::Error)

  # DSL for defining settings and sections within a Fino.configure block.
  #
  #   Fino.configure do
  #     settings do
  #       setting :timeout, :integer, default: 30
  #       section :openai, label: "OpenAI" do
  #         setting :model, :string, default: "gpt-5"
  #       end
  #     end
  #   end
  class DSL
    # DSL context for defining settings within a section.
    class SectionDSL
      def initialize(section_definition, registry)
        @section_definition = section_definition
        @registry = registry
      end

      # Defines a setting within the current section.
      #
      # +setting_name+ - Symbol name of the setting.
      # +type+ - Symbol type identifier (+:string+, +:integer+, +:float+, or +:boolean+).
      # +options+ - Additional keyword arguments (+default:+, +description:+, +unit:+).
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

    # Defines a top-level setting (not scoped to a section).
    #
    # +setting_name+ - Symbol name of the setting.
    # +type+ - Symbol type identifier (+:string+, +:integer+, +:float+, or +:boolean+).
    # +options+ - Additional keyword arguments (+default:+, +description:+, +unit:+).
    #
    #   setting :api_rate_limit, :integer, default: 1000, description: "Max requests/min"
    def setting(setting_name, type, **)
      @registry.register(
        Fino::Definition::Setting.new(
          type: type,
          setting_name: setting_name,
          **
        )
      )
    end

    # Defines a section that groups related settings.
    #
    # +section_name+ - Symbol name of the section.
    # +options+ - Optional hash with +:label+ for display purposes.
    #
    # The block is evaluated in the context of SectionDSL.
    #
    #   section :openai, label: "OpenAI" do
    #     setting :model, :string, default: "gpt-5"
    #   end
    def section(section_name, options = {}, &)
      section_definition = Fino::Definition::Section.new(
        name: section_name,
        **options
      )

      @registry.register_section(section_definition)

      SectionDSL.new(section_definition, @registry).instance_eval(&)
    end
  end

  using Fino::Ext::Hash

  # Returns the Set of all registered Fino::Definition::Setting instances.
  attr_reader :setting_definitions

  # Returns the Set of all registered Fino::Definition::Section instances.
  attr_reader :section_definitions

  def initialize
    @setting_definitions = Set.new
    @setting_definitions_by_path = {}

    @section_definitions = Set.new
    @section_definitions_by_name = {}
  end

  # Looks up a setting definition by path components.
  #
  # +path+ - One or two arguments: +setting_name+ or +setting_name, section_name+.
  #          Nil components are stripped.
  #
  # Returns the Fino::Definition::Setting, or +nil+ if not found.
  def setting_definition(*path)
    @setting_definitions_by_path.dig(*path.compact.reverse.map(&:to_s))
  end

  # Same as #setting_definition but raises Fino::Registry::UnknownSetting
  # when the definition is not found.
  def setting_definition!(*path)
    setting_definition(*path).tap do |definition|
      raise UnknownSetting, "Unknown setting: #{path.compact.join('.')}" unless definition
    end
  end

  # Returns setting definitions, optionally filtered by section.
  #
  # When called with no arguments, returns all definitions.
  # When +at:+ is +nil+, returns only unsectioned (top-level) settings.
  # When +at:+ is a section name, returns settings in that section.
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

  # Returns the Fino::Definition::Section for the given name, or +nil+.
  def section_definition(section_name)
    @section_definitions_by_name[section_name.to_s]
  end

  # Registers a new setting definition.
  #
  # Raises DuplicateSetting if a setting with the same key is already registered.
  def register(setting_definition)
    unless @setting_definitions.add?(setting_definition)
      raise DuplicateSetting, "#{setting_definition.setting_name} is already registered at #{setting_definition.key}"
    end

    @setting_definitions_by_path.deep_set(setting_definition, *setting_definition.path.map(&:to_s))
  end

  # Registers a new section definition. Silently ignores duplicates.
  def register_section(section_definition)
    return unless @section_definitions.add?(section_definition)

    @section_definitions_by_name[section_definition.name.to_s] = section_definition
  end
end
