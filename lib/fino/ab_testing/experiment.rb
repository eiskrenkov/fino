# frozen_string_literal: true

class Fino::AbTesting::Experiment
  include Fino::PrettyInspectable

  TOTAL_PERCENTAGE = 100.0

  attr_reader :setting_definition

  def initialize(setting_definition)
    @setting_definition = setting_definition
    @user_variants = []
  end

  def <<(variant)
    @user_variants << variant

    @variants = nil
    @value_by_variant_id = nil
  end

  def variants
    return @variants if @variants
    return @variants = [] if @user_variants.empty?

    @variants = [
      Fino::AbTesting::Variant.new(
        percentage: TOTAL_PERCENTAGE - @user_variants.sum(&:percentage),
        value: Fino::AbTesting::Variant::CONTROL_VALUE
      ),
      *@user_variants
    ]
  end

  def value(for:)
    variant = variant(for: binding.local_variable_get(:for))

    value_by_variant_id.fetch(
      variant.id,
      Fino::AbTesting::Variant::CONTROL_VALUE
    )
  end

  def variant(for:)
    Fino::AbTesting::VariantPicker.new(setting_definition).call(
      variants,
      binding.local_variable_get(:for)
    )
  end

  private

  def value_by_variant_id
    @value_by_variant_id ||= variants.each_with_object({}) do |variant, memo|
      memo[variant.id] = variant.value
    end
  end

  def inspectable_attributes
    {
      variants: variants
    }
  end
end
