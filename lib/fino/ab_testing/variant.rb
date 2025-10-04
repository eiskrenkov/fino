# frozen_string_literal: true

class Fino::AbTesting::Variant
  CONTROL_VALUE = Class.new do
    def inspect
      "Fino::AbTesting::Variant::CONTROL_VALUE"
    end
  end.new

  include Fino::PrettyInspectable

  attr_reader :id, :percentage, :value

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
