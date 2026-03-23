# frozen_string_literal: true

module Fino::Adapter
  AB_TESTING_ANALYSIS_METHODS = %i[record_ab_testing_conversion read_ab_testing_conversions clear_ab_testing_conversions].freeze

  def supports_ab_testing_analysis?
    AB_TESTING_ANALYSIS_METHODS.all? { |method| respond_to?(method) }
  end

  def read(setting_key)
    raise NotImplementedError
  end

  def read_multi(setting_keys)
    raise NotImplementedError
  end

  def write(setting_definition, value, overrides, variants)
    raise NotImplementedError
  end

  def read_persisted_setting_keys
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
