# frozen_string_literal: true

module Fino::Setting
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

    def build(setting_definition, raw_value, scoped_raw_values)
      value = raw_value.equal?(Fino::EMPTINESS) ? setting_definition.options[:default] : deserialize(raw_value)
      scoped_values = scoped_raw_values.transform_values { |v| deserialize(v) }

      new(
        setting_definition,
        value,
        scoped_values
      )
    end
  end

  attr_reader :definition

  def initialize(definition, value, scoped_values = {})
    @definition = definition
    @value = value
    @scoped_values = scoped_values
  end

  def name
    definition.setting_name
  end

  def key
    definition.key
  end

  def value(scope: nil)
    scope ? scoped_values.fetch(scope.to_s, @value) : @value
  end

  def overriden_scopes
    scoped_values.keys
  end

  def scope_overrides
    scoped_values
  end

  def type
    definition.type
  end

  def type_class
    definition.type_class
  end

  def section_definition
    definition.section_definition
  end

  def section_name
    definition.section_definition&.name
  end

  def default
    definition.default
  end

  def description
    definition.description
  end

  def inspect
    attributes = [
      "key=#{key.inspect}",
      "type=#{type_class.inspect}",
      "value=#{value.inspect}",
      "default=#{default.inspect}"
    ]

    "#<#{self.class.name} #{attributes.join(', ')}>"
  end

  private

  attr_reader :scoped_values
end
