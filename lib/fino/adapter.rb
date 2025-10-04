# frozen_string_literal: true

module Fino::Adapter
  def read(setting_definition)
    raise NotImplementedError
  end

  def read_multi(setting_definitions)
    raise NotImplementedError
  end

  def write(setting_definition, value, overrides, variants)
    raise NotImplementedError
  end

  def fetch_value_from(raw_adapter_data)
    raise NotImplementedError
  end

  def fetch_raw_overrides_from(raw_adapter_data)
    raise NotImplementedError
  end

  def fetch_raw_variants_from(raw_adapter_data)
    raise NotImplementedError
  end
end
