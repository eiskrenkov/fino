# frozen_string_literal: true

class Fino::Pipe::Storage
  include Fino::Pipe

  def initialize(adapter)
    @adapter = adapter
  end

  def read(setting_definition)
    to_setting(setting_definition, adapter.read(setting_definition))
  end

  def read_multi(setting_definitions)
    setting_definitions.zip(adapter.read_multi(setting_definitions)).map do |definition, raw_data|
      to_setting(definition, raw_data)
    end
  end

  def write(setting_definition, value, overrides, variants)
    adapter.write(setting_definition, value, overrides, variants)
  end

  private

  attr_reader :adapter

  def to_setting(setting_definition, raw_adapter_data)
    raw_value = adapter.fetch_value_from(raw_adapter_data)
    scoped_raw_values = adapter.fetch_scoped_values_from(raw_adapter_data)
    raw_variants = adapter.fetch_raw_variants_from(raw_adapter_data)

    setting_definition.type_class.build(
      setting_definition,
      raw_value,
      scoped_raw_values,
      raw_variants
    )
  end
end
