# frozen_string_literal: true

module Fino::Setting
  UNSET_VALUE = Object.new.freeze

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def serialize(value)
      raise NotImplementedError
    end

    def deserialize(raw_value)
      raise NotImplementedError
    end

    def build(setting_definition, raw_value, *options)
      new(
        setting_definition,
        raw_value.equal?(UNSET_VALUE) ? setting_definition.options[:default] : deserialize(raw_value),
        *options
      )
    end
  end

  attr_reader :name, :section_name, :value, :options

  def initialize(setting_definition, value, **options)
    @name = setting_definition.setting_name
    @section_name = setting_definition.section_name
    @value = value

    @options = options
  end
end
