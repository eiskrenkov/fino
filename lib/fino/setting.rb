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

  attr_reader :definition, :value

  def initialize(definition, value, **options)
    @definition = definition
    @value = value

    @options = options
  end

  def name
    definition.setting_name
  end

  def section_name
    definition.section_name
  end

  def default
    definition.default
  end
end
