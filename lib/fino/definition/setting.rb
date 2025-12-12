# frozen_string_literal: true

class Fino::Definition::Setting
  TYPE_CLASSES = [
    Fino::Settings::String,
    Fino::Settings::Integer,
    Fino::Settings::Float,
    Fino::Settings::Boolean
  ].freeze

  SETTING_TYPE_TO_TYPE_CLASS_MAPPING = TYPE_CLASSES.each_with_object({}) do |klass, hash|
    hash[klass.type_identifier] = klass
  end.freeze

  attr_reader :setting_name, :section_definition, :type, :options

  def initialize(type:, setting_name:, section_definition: nil, **options)
    @setting_name = setting_name
    @section_definition = section_definition
    @type = type
    @options = options
  end

  def type_class
    @type_class ||= SETTING_TYPE_TO_TYPE_CLASS_MAPPING.fetch(type) do
      raise ArgumentError, "Unknown setting type #{type}"
    end
  end

  def default
    defined?(@default) ? @default : @default = type_class.deserialize(options[:default])
  end

  def description
    defined?(@description) ? @description : @description = options[:description]
  end

  def path
    @path ||= [setting_name, section_definition&.name].compact
  end

  def key
    @key ||= path.reverse.join("/")
  end

  def eql?(other)
    self.class.eql?(other.class) && key == other.key
  end
  alias == eql?

  def hash
    key.hash
  end
end
