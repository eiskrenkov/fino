# frozen_string_literal: true

module Fino::Setting
  UNSET_VALUE = Object.new.freeze

  class << self
    def serialize(value)
      raise NotImplementedError
    end

    def deserialize(raw_value)
      raise NotImplementedError
    end
  end

  attr_reader :name, :section_name, :raw_value, :default, :options

  def initialize(setting_definition, raw_value, **options)
    @name = setting_definition.setting_name
    @section_name = setting_definition.section_name
    @raw_value = raw_value

    @default = setting_definition.options[:default]
    @options = options
  end

  def value
    return @value if defined?(@value)

    @value = raw_value.equal?(UNSET_VALUE) ? default : self.class.deserialize(raw_value)
  end
end
