# frozen_string_literal: true

# Abstract interface for storage adapters.
#
# Implementations must include this module and define all methods to provide
# persistence for setting values, overrides, and A/B testing variants.
#
# == Built-in Implementations
#
# - +Fino::Redis::Adapter+ -- Redis-backed storage (in the +fino-redis+ gem)
# - +Fino::Solid::Adapter+ -- Database-backed storage via Rails (in the +fino-solid+ gem)
#
# == Implementing a Custom Adapter
#
#   class MyAdapter
#     include Fino::Adapter
#
#     def read(setting_key)
#       # Return raw data hash for the setting, or nil
#     end
#
#     def read_multi(setting_keys)
#       # Return array of raw data hashes (one per key)
#     end
#
#     def write(setting_definition, value, overrides, variants)
#       # Persist the setting
#     end
#     # ...
#   end
module Fino::Adapter
  # Reads raw data for a single setting from storage.
  #
  # +setting_key+ - String key (e.g. +"openai/model"+).
  #
  # Returns a Hash of raw adapter data, or +nil+ if not persisted.
  def read(setting_key)
    raise NotImplementedError
  end

  # Reads raw data for multiple settings from storage.
  #
  # +setting_keys+ - Array of String keys.
  #
  # Returns an Array of raw data Hashes (one per key).
  def read_multi(setting_keys)
    raise NotImplementedError
  end

  # Persists a setting with its value, overrides, and variants.
  #
  # +setting_definition+ - Fino::Definition::Setting instance.
  # +value+ - The deserialized global value.
  # +overrides+ - Hash of scope overrides.
  # +variants+ - Array of Fino::AbTesting::Variant instances.
  def write(setting_definition, value, overrides, variants)
    raise NotImplementedError
  end

  # Returns an Array of String keys for all settings persisted in storage.
  def read_persisted_setting_keys
    raise NotImplementedError
  end

  # Extracts the setting value from raw adapter data.
  def fetch_value_from(raw_adapter_data)
    raise NotImplementedError
  end

  # Extracts raw override data from raw adapter data.
  def fetch_raw_overrides_from(raw_adapter_data)
    raise NotImplementedError
  end

  # Extracts raw A/B variant data from raw adapter data.
  def fetch_raw_variants_from(raw_adapter_data)
    raise NotImplementedError
  end
end
