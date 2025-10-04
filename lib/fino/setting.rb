# frozen_string_literal: true

module Fino::Setting
  include Fino::PrettyInspectable

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
  end

  attr_reader :definition, :global_value, :overrides, :variants

  def initialize(definition, global_value, overrides = {}, variants = [])
    @definition = definition
    @global_value = global_value
    @overrides = overrides
    @variants = variants
  end

  def value(**context)
    return global_value unless (scope = context[:for])

    overrides.fetch(scope.to_s) do
      return global_value if variants.empty?

      variant = variant(for: scope)
      result = value_by_variant_id.fetch(variant.id, global_value)

      return global_value if result == Fino::Variant::CONTROL_VALUE

      result
    end
  end

  def variant(for:)
    Fino::VariantPicker.new(self).call(
      binding.local_variable_get(:for)
    )
  end

  def name
    definition.setting_name
  end

  def key
    definition.key
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

  private

  def value_by_variant_id
    @value_by_variant_id ||= variants.each_with_object({}) do |variant, memo|
      memo[variant.id] = variant.value
    end
  end

  def inspectable_attributes
    {
      key: key,
      type: type_class,
      default: default,
      global_value: global_value,
      overrides: overrides,
      variants: variants
    }
  end
end
