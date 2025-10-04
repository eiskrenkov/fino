# frozen_string_literal: true

Fino::Variant = Struct.new(:percentage, :value) do
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

Fino::Variant::CONTROL_VALUE = Class.new do
  def inspect
    "Fino::Variant::CONTROL_VALUE"
  end
end.new
