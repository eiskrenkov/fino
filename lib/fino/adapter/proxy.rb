# frozen_string_literal: true

class Fino::Adapter::Proxy
  def initialize(adapter, registry)
    @adapter = adapter
    @registry = registry
  end

  def setting(setting_definition)
    to_setting(setting_definition, adapter.read(setting_definition))
  end

  def all
    definitions = registry.setting_definitions

    definitions.zip(adapter.read_multi(definitions)).map do |definition, raw_data|
      to_setting(definition, raw_data)
    end
  end

  private

  attr_reader :adapter, :registry

  def to_setting(setting_definition, raw_adapter_data)
    raw_value = adapter.fetch_value_from(raw_adapter_data)

    setting_definition.type_class.new(
      setting_definition,
      raw_value,
      **raw_adapter_data
    )
  end
end
