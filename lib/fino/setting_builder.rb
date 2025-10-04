# frozen_string_literal: true

class Fino::SettingBuilder
  attr_reader :setting_definition

  def initialize(setting_definition)
    @setting_definition = setting_definition
  end

  def call(raw_value, raw_overrides, raw_variants)
    global_value = deserialize_global_value(raw_value)
    overrides = deserialize_overrides(raw_overrides)
    variants = deserialize_variants(raw_variants)

    setting_definition.type_class.new(
      setting_definition,
      global_value,
      overrides,
      variants
    )
  end

  private

  def deserialize_global_value(raw_value)
    return setting_definition.options[:default] if raw_value.equal?(Fino::EMPTINESS)

    deserialize(raw_value)
  end

  def deserialize_overrides(raw_overrides)
    raw_overrides.transform_values { |v| deserialize(v) }
  end

  def deserialize_variants(raw_variants)
    variants = raw_variants.map do |raw_variant|
      Fino::Variant.new(
        raw_variant.fetch(:percentage),
        deserialize(raw_variant.fetch(:value))
      )
    end

    variants.prepend(
      Fino::Variant.new(percentage: 100.0 - variants.sum(&:percentage), value: Fino::Variant::CONTROL_VALUE)
    )

    variants
  end

  def deserialize(value)
    setting_definition.type_class.deserialize(value)
  end
end
