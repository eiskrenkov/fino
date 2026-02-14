# frozen_string_literal: true

# Describes a single setting: its name, type, section, and options.
#
# Setting definitions are created by the registry DSL and stored in the
# Fino::Registry. They are used by the library to look up type classes,
# default values, and storage keys.
#
# == Supported Types
#
# - +:string+  -- Fino::Settings::String
# - +:integer+ -- Fino::Settings::Integer
# - +:float+   -- Fino::Settings::Float
# - +:boolean+ -- Fino::Settings::Boolean
#
# == Options
#
# - +default:+ -- Default value (deserialized via the type class)
# - +description:+ -- Human-readable description
# - +unit:+ -- Unit identifier for numeric types (+:ms+, +:sec+)
class Fino::Definition::Setting
  # All registered type classes.
  TYPE_CLASSES = [
    Fino::Settings::String,
    Fino::Settings::Integer,
    Fino::Settings::Float,
    Fino::Settings::Boolean
  ].freeze

  # Maps Symbol type identifiers to their type classes.
  SETTING_TYPE_TO_TYPE_CLASS_MAPPING = TYPE_CLASSES.each_with_object({}) do |klass, hash|
    hash[klass.type_identifier] = klass
  end.freeze

  # Returns the Symbol name of this setting (e.g. +:model+).
  attr_reader :setting_name

  # Returns the Fino::Definition::Section this setting belongs to, or +nil+.
  attr_reader :section_definition

  # Returns the Symbol type identifier (+:string+, +:integer+, +:float+, +:boolean+).
  attr_reader :type

  # Returns the Hash of additional options (+default:+, +description:+, +unit:+, etc.).
  attr_reader :options

  def initialize(type:, setting_name:, section_definition: nil, **options)
    @setting_name = setting_name
    @section_definition = section_definition
    @type = type
    @options = options
  end

  # Returns the setting type class (e.g. Fino::Settings::String).
  #
  # Raises +ArgumentError+ for unknown type identifiers.
  def type_class
    @type_class ||= SETTING_TYPE_TO_TYPE_CLASS_MAPPING.fetch(type) do
      raise ArgumentError, "Unknown setting type #{type}"
    end
  end

  # Returns the deserialized default value, or +nil+ if none was provided.
  def default
    defined?(@default) ? @default : @default = type_class.deserialize(options[:default])
  end

  # Returns the description string, or +nil+.
  def description
    defined?(@description) ? @description : @description = options[:description]
  end

  # Returns the path components as an Array (e.g. +[:model, :openai]+).
  def path
    @path ||= [setting_name, section_definition&.name].compact
  end

  # Returns the storage key string (e.g. +"openai/model"+).
  def key
    @key ||= path.reverse.join("/")
  end

  # Two definitions are equal if they have the same class and key.
  def eql?(other)
    self.class.eql?(other.class) && key == other.key
  end
  alias == eql?

  # Hash code based on the key, for use in Sets and Hash keys.
  def hash
    key.hash
  end
end
