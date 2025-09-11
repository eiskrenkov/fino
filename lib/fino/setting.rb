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

    def build(setting_definition, raw_value, *options)
      new(
        setting_definition,
        raw_value.equal?(Fino::EMPTINESS) ? setting_definition.options[:default] : deserialize(raw_value),
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

  def key
    definition.key
  end

  def section_name
    definition.section_name
  end

  def default
    definition.default
  end

  def inspect
    attributes = [
      "key=#{key.inspect}",
      "value=#{value.inspect}",
      "default=#{default.inspect}"
    ]

    "#<#{self.class.name} #{attributes.join(', ')}>"
  end
end
