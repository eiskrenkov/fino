# frozen_string_literal: true

module Fino::Adapter
  VALUE_KEY = "value"

  def initialize(registry)
    @registry = registry
  end

  def setting(setting_definition)
    to_setting(setting_definition, read(setting_definition))
  end

  def value(setting_definition)
    setting(setting_definition).value
  end

  def all
    registry.setting_definitions.zip(read_multi(registry.setting_definitions)).map do |definition, raw_data|
      to_setting(definition, raw_data)
    end
  end

  protected

  def read(setting_definition)
    raise NotImplementedError
  end

  def read_multi(setting_definitions)
    raise NotImplementedError
  end

  def write(setting_definition, value)
    raise NotImplementedError
  end

  private

  attr_reader :registry

  def to_setting(setting_definition, raw_adapter_data)
    raw_value = raw_adapter_data.key?(VALUE_KEY) ? raw_adapter_data.delete(VALUE_KEY) : Fino::Setting::UNSET_VALUE

    setting_definition.type_class.new(
      setting_definition,
      raw_value,
      **raw_adapter_data
    )
  end
end
