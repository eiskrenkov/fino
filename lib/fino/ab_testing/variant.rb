# frozen_string_literal: true

Fino::AbTesting::Variant = Struct.new(:percentage, :value, keyword_init: true) do
  include Fino::PrettyInspectable

  def id = @id ||= SecureRandom.uuid

  private

  def inspectable_attributes
    {
      percentage: percentage,
      value: value
    }
  end
end

Fino::AbTesting::Variant::CONTROL_VALUE = Class.new do
  def inspect
    "Fino::AbTesting::Variant::CONTROL_VALUE"
  end
end.new
