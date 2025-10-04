# frozen_string_literal: true

class Fino::SettingBuilder
  attr_reader :setting_definition

  def initialize(setting_definition)
    @setting_definition = setting_definition
  end

  def call(raw_value, raw_overrides, raw_variants)
    global_value = deserialize_global_value(raw_value)
    overrides = deserialize_overrides(raw_overrides)
    experiment = deserialize_experiment(raw_variants)

    setting_definition.type_class.new(
      setting_definition,
      global_value,
      overrides,
      experiment
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

  def deserialize_experiment(raw_variants)
    return if raw_variants.empty?

    Fino::AbTesting::Experiment.new(setting_definition).tap do |experiment|
      raw_variants.each do |raw_variant|
        experiment << Fino::AbTesting::Variant.new(
          percentage: raw_variant.fetch(:percentage),
          value: deserialize(raw_variant.fetch(:value))
        )
      end
    end
  end

  def deserialize(value)
    setting_definition.type_class.deserialize(value)
  end
end
