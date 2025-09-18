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

    def build(setting_definition, raw_value, scoped_raw_values, raw_variants)
      value = raw_value.equal?(Fino::EMPTINESS) ? setting_definition.options[:default] : deserialize(raw_value)
      scoped_values = scoped_raw_values.transform_values { |v| deserialize(v) }

      variants = raw_variants.map do |raw_variant|
        Fino::Variant.new(
          raw_variant.fetch(:percentage),
          deserialize(raw_variant.fetch(:value))
        )
      end

      new(
        setting_definition,
        value,
        scoped_values,
        variants
      )
    end
  end

  attr_reader :definition, :variants

  def initialize(definition, value, scoped_values = {}, variants = [])
    @definition = definition
    @value = value
    @scoped_values = scoped_values
    @variants = variants
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
      return @value if variants.empty?

      variant = variant(for: scope)
      result = variant_id_to_value.fetch(variant.id, @value)

      return @value if result == Fino::Variant::CONTROL

      result
    end
  end

  def variant(for:)
    Fino::VariantPicker.new(self).call(
      binding.local_variable_get(:for)
    )
  end

  def variant_id_to_value
    @variant_id_to_value ||= variants.each_with_object({}) do |variant, memo|
      memo[variant.id] = variant.value
    end
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
      "variants=#{variants.inspect}",
      "default=#{default.inspect}"
    ]

    "#<#{self.class.name} #{attributes.join(', ')}>"
  end

  private

  attr_reader :scoped_values
end
