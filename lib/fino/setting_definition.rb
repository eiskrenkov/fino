# frozen_string_literal: true

class Fino::SettingDefinition
  attr_reader :setting_name, :section_name, :type, :options

  def initialize(type:, setting_name:, section_name: nil, **options)
    @setting_name = setting_name
    @section_name = section_name
    @type = type
    @options = options
  end

  def type_class
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
    options[:default]
  end

  def path
    @path ||= [setting_name, section_name].compact
  end

  def key
    path.join("_")
  end
end
