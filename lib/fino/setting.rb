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

    def build(setting_definition, raw_value, scoped_raw_values, variant_raw_values)
      value = raw_value.equal?(Fino::EMPTINESS) ? setting_definition.options[:default] : deserialize(raw_value)
      scoped_values = scoped_raw_values.transform_values { |v| deserialize(v) }
      variant_values = variant_raw_values.transform_values { |v| deserialize(v) }

      new(
        setting_definition,
        value,
        scoped_values,
        variant_values
      )
    end
  end

  attr_reader :definition

  def initialize(definition, value, scoped_values = {}, variant_values = {})
    @definition = definition
    @value = value
    @scoped_values = scoped_values
    @variant_values = variant_values
  end

  def name
    definition.setting_name
  end

  def key
    definition.key
  end

  def value(**context)
    return @value unless (scope = context[:for])

    scoped_values.fetch(scope.to_s) do
      return @value if @variant_values.empty?

      variant = variant(for: scope)
      Fino.logger.debug { "Variant picked: #{variant}" }

      variant_id_to_value.fetch(variant.id, @value)
    end
  end

  def variant(for:)
    Fino::VariantPicker.new(self).call(
      binding.local_variable_get(:for)
    )
  end

  def variants
    @variant_values.keys
  end

  def variant_id_to_value
    @variant_id_to_value ||= @variant_values.transform_keys(&:id)
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
      "overrides=#{@scoped_values.inspect}",
      "variants=#{@variant_values.inspect}",
      "default=#{default.inspect}"
    ]

    "#<#{self.class.name} #{attributes.join(', ')}>"
  end

  private

  attr_reader :scoped_values
end
