# frozen_string_literal: true

class Fino::Pipe::Storage
  include Fino::Pipe

  def initialize(adapter)
    @adapter = adapter
  end

  def read(setting_definition)
    to_setting(setting_definition, adapter.read(setting_definition.key))
  end

  def read_multi(setting_definitions)
    setting_definitions.zip(adapter.read_multi(setting_definitions.map(&:key))).map do |definition, raw_data|
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
    raw_overrides = adapter.fetch_raw_overrides_from(raw_adapter_data)
    raw_variants = adapter.fetch_raw_variants_from(raw_adapter_data)

    Fino::SettingBuilder.new(setting_definition).call(raw_value, raw_overrides, raw_variants)
  end
end
