# frozen_string_literal: true

# Represents an A/B testing experiment attached to a setting.
#
# An experiment consists of a control group (the global setting value) and
# one or more user-defined variants with percentage-based traffic splits.
# The control variant automatically receives the remaining percentage.
#
# == Example
#
#   Fino.set(model: "gpt-5", at: :openai, variants: { 20.0 => "gpt-6" })
#
#   experiment = Fino.setting(:model, at: :openai).experiment
#   experiment.variant(for: "user_1")  #=> <Variant percentage: 20.0, value: "gpt-6">
#   experiment.value(for: "user_1")    #=> "gpt-6"
class Fino::AbTesting::Experiment
  include Fino::PrettyInspectable

  # The total percentage across all variants (control + user variants).
  TOTAL_PERCENTAGE = 100.0

  # Returns the Fino::Definition::Setting this experiment belongs to.
  attr_reader :setting_definition

  def initialize(setting_definition)
    @setting_definition = setting_definition
    @user_variants = []
  end

  # Adds a variant to the experiment, resetting cached variant lists.
  def <<(variant)
    @user_variants << variant

    @variants = nil
    @value_by_variant_id = nil
  end

  # Returns all variants including the auto-generated control variant.
  #
  # The control variant receives the remaining percentage after subtracting
  # all user variant percentages from 100%.
  #
  # Returns an empty Array if no variants have been added.
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

  # Returns the variant value for the given scope.
  #
  # If the scope falls into the control group, returns
  # Fino::AbTesting::Variant::CONTROL_VALUE, which signals the library
  # to use the global setting value instead.
  #
  # +for+ - A scope identifier (e.g. user ID string).
  def value(for:)
    variant = variant(for: binding.local_variable_get(:for))

    value_by_variant_id.fetch(
      variant.id,
      Fino::AbTesting::Variant::CONTROL_VALUE
    )
  end

  # Returns the Fino::AbTesting::Variant assigned to the given scope.
  #
  # Uses deterministic CRC32 hashing to ensure the same scope always
  # receives the same variant (sticky assignment).
  #
  # +for+ - A scope identifier (e.g. user ID string).
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
