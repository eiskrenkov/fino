# frozen_string_literal: true

class Fino::AbTesting::Variant
  CONTROL_VALUE = Class.new do
    def inspect
      "Fino::AbTesting::Variant::CONTROL_VALUE"
    end

    def to_s
      "control"
    end
  end.new

  include Fino::PrettyInspectable

  attr_reader :percentage, :value

  def initialize(percentage:, value:)
    @percentage = percentage.to_f
    @value = value
  end

  def id
    "#{percentage}-#{value}"
  end

  private

  def inspectable_attributes
    {
      percentage: percentage,
      value: value
    }
  end
end
