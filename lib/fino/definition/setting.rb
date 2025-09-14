# frozen_string_literal: true

class Fino::Definition::Setting
  attr_reader :setting_name, :section_definition, :type, :options

  def initialize(type:, setting_name:, section_definition: nil, **options)
    @setting_name = setting_name
    @section_definition = section_definition
    @type = type
    @options = options
  end

  def type_class # rubocop:disable Metrics/MethodLength
    @type_class ||=
      case type
      when :string
        Fino::Settings::String
      when :integer
        Fino::Settings::Integer
      when :float
        Fino::Settings::Float
      when :boolean
        Fino::Settings::Boolean
      else
        raise "Unknown type #{type}"
      end
  end

  def default
    return @default if defined?(@default)

    @default = options[:default]
  end

  def description
    options[:description]
  end

  def path
    @path ||= [setting_name, section_definition&.name].compact
  end

  def key
    @key ||= path.reverse.join("/")
  end
end
