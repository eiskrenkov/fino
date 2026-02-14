# frozen_string_literal: true

# Represents a single variant in an A/B testing experiment.
#
# Each variant has a percentage (traffic allocation) and a value. The
# special CONTROL_VALUE sentinel indicates the control group, which uses
# the setting's global value.
class Fino::AbTesting::Variant
  # Sentinel value representing the control group. When a scope is assigned
  # to the control variant, the setting's global value is used instead.
  CONTROL_VALUE = Class.new do
    def inspect
      "Fino::AbTesting::Variant::CONTROL_VALUE"
    end
  end.new

  include Fino::PrettyInspectable

  # Returns the unique identifier (UUID) for this variant.
  attr_reader :id

  # Returns the percentage of traffic allocated to this variant (0.0-100.0).
  attr_reader :percentage

  # Returns the variant value, or CONTROL_VALUE for the control group.
  attr_reader :value

  def initialize(percentage:, value:)
    @id = SecureRandom.uuid

    @percentage = percentage.to_f
    @value = value
  end

  private

  def inspectable_attributes
    {
      percentage: percentage,
      value: value
    }
  end
end
