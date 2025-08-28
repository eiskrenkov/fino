# frozen_string_literal: true

class Fino::SettingDefinition
  attr_reader :setting_name, :section_name, :type

  def initialize(setting_name, section_name = nil, type)
    @setting_name = setting_name
    @section_name = section_name
    @type = type
  end

  def type_class
    case type
    when :string
      Fino::Settings::String
    else
      raise "Unknown type #{type}"
    end
  end

  def path
    section_name.nil? ? [setting_name] : [section_name, setting_name]
  end

  def key
    path.join("_")
  end
end
