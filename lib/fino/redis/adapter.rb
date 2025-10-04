# frozen_string_literal: true

class Fino::Redis::Adapter
  include Fino::Adapter

  using Fino::CustomRedisScripts

  DEFAULT_REDIS_NAMESPACE = "fino"
  SCOPE_PREFIX = "s"
  VARIANT_PREFIX = "v"
  VALUE_KEY = "v"

  def initialize(redis, namespace: DEFAULT_REDIS_NAMESPACE)
    @redis = redis
    @redis_namespace = namespace
  end

  def read(setting_definition)
    redis.hgetall(redis_key_for(setting_definition))
  end

  def read_multi(setting_definitions)
    keys = setting_definitions.map { |definition| redis_key_for(definition) }

    redis.pipelined do |pipeline|
      keys.each { |key| pipeline.hgetall(key) }
    end
  end

  def write(setting_definition, value, overrides, variants)
    serialize_value = ->(raw_value) { setting_definition.type_class.serialize(raw_value) }

    hash = { VALUE_KEY => serialize_value.call(value) }

    overrides.each do |scope, value|
      hash["#{SCOPE_PREFIX}/#{scope}/#{VALUE_KEY}"] = serialize_value.call(value)
    end

    variants.each do |variant|
      next if variant.value == Fino::AbTesting::Variant::CONTROL_VALUE

      hash["#{VARIANT_PREFIX}/#{variant.percentage}/#{VALUE_KEY}"] = serialize_value.call(variant.value)
    end

    redis.mapped_hreplace(redis_key_for(setting_definition), hash)
  end

  def fetch_value_from(raw_adapter_data)
    raw_adapter_data.key?(VALUE_KEY) ? raw_adapter_data.delete(VALUE_KEY) : Fino::EMPTINESS
  end

  def fetch_raw_overrides_from(raw_adapter_data)
    raw_adapter_data.each_with_object({}) do |(key, value), memo|
      next unless key.start_with?("#{SCOPE_PREFIX}/")

      scope = key.split("/", 3)[1]
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

  private

  attr_reader :redis, :redis_namespace

  def redis_key_for(setting_definition)
    "#{redis_namespace}:#{setting_definition.path.join(':')}"
  end
end
