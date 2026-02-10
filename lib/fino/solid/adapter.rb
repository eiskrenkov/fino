# frozen_string_literal: true

module Fino
  module Solid
    class Adapter
      include Fino::Adapter

      SCOPE_PREFIX = "s"
      VARIANT_PREFIX = "v"
      VALUE_KEY = "v"

      def read(setting_key)
        setting = Fino::Solid::Setting.find_by(key: setting_key)
        setting&.data || {}
      end

      def read_multi(setting_keys)
        settings_by_key = Fino::Solid::Setting.where(key: setting_keys).index_by(&:key)

        setting_keys.map { |key| settings_by_key[key]&.data || {} }
      end

      def write(setting_definition, value, overrides, variants)
        serialize_value = ->(raw_value) { setting_definition.type_class.serialize(raw_value) }

        data = { VALUE_KEY => serialize_value.call(value) }

        overrides.each do |scope, scope_value|
          data["#{SCOPE_PREFIX}/#{scope}/#{VALUE_KEY}"] = serialize_value.call(scope_value)
        end

        variants.each do |variant|
          next if variant.value == Fino::AbTesting::Variant::CONTROL_VALUE

          data["#{VARIANT_PREFIX}/#{variant.percentage}/#{VALUE_KEY}"] = serialize_value.call(variant.value)
        end

        Fino::Solid::Setting.upsert(
          { key: setting_definition.key, data: data },
          unique_by: :key
        )
      end

      def read_persisted_setting_keys
        Fino::Solid::Setting.pluck(:key)
      end

      def clear(setting_key)
        Fino::Solid::Setting.where(key: setting_key).delete_all > 0
      end

      def fetch_value_from(raw_adapter_data)
        raw_adapter_data.key?(VALUE_KEY) ? raw_adapter_data.delete(VALUE_KEY) : Fino::EMPTINESS
      end

      def fetch_raw_overrides_from(raw_adapter_data)
        raw_adapter_data.each_with_object({}) do |(key, value), memo|
          next unless key.start_with?("#{SCOPE_PREFIX}/")

          scope = key.delete_prefix("#{SCOPE_PREFIX}/").delete_suffix("/#{VALUE_KEY}")
          memo[scope] = value
        end
      end

      def fetch_raw_variants_from(raw_adapter_data)
        raw_adapter_data.each_with_object([]) do |(key, value), memo|
          next unless key.start_with?("#{VARIANT_PREFIX}/")

          percentage = key.split("/", 3)[1]

          memo << { percentage: percentage.to_f, value: value }
        end
      end
    end
  end
end
