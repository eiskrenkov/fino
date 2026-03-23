# frozen_string_literal: true

class Fino::Redis::Adapter
  include Fino::Adapter

  using Fino::CustomRedisScripts

  DEFAULT_REDIS_NAMESPACE = "fino"
  SETTINGS_NAMESPACE = "s"
  CONVERSIONS_NAMESPACE = "c"
  CONVERSIONS_KEYS_NAMESPACE = "ck"
  CONVERSIONS_TTL = 7 * 24 * 60 * 60 # 7 days
  PERSISTED_SETTINGS_KEYS_REDIS_KEY = "psl"
  SCOPE_PREFIX = "s"
  VARIANT_PREFIX = "v"
  VALUE_KEY = "v"

  def initialize(redis, namespace: DEFAULT_REDIS_NAMESPACE)
    @redis = redis
    @redis_namespace = namespace
  end

  def read(setting_key)
    redis.hgetall(redis_key_for(setting_key))
  end

  def read_multi(setting_keys)
    keys = setting_keys.map { |setting_key| redis_key_for(setting_key) }

    redis.pipelined do |pipeline|
      keys.each { |key| pipeline.hgetall(key) }
    end
  end

  def write(setting_definition, value, overrides, variants)
    serialize_value = ->(raw_value) { setting_definition.serialize(raw_value) }

    hash = { VALUE_KEY => serialize_value.call(value) }

    overrides.each do |scope, value|
      hash["#{SCOPE_PREFIX}/#{scope}/#{VALUE_KEY}"] = serialize_value.call(value)
    end

    variants.each do |variant|
      next if variant.value == Fino::AbTesting::Variant::CONTROL_VALUE

      hash["#{VARIANT_PREFIX}/#{variant.percentage}/#{VALUE_KEY}"] = serialize_value.call(variant.value)
    end

    redis.multi do |r|
      r.mapped_hreplace(redis_key_for(setting_definition.key), hash)
      r.sadd(build_redis_key(PERSISTED_SETTINGS_KEYS_REDIS_KEY), setting_definition.key)
    end
  end

  def read_persisted_setting_keys
    redis.smembers(build_redis_key(PERSISTED_SETTINGS_KEYS_REDIS_KEY))
  end

  def clear(setting_key)
    _, cleared = redis.multi do |r|
      r.del(redis_key_for(setting_key))
      r.srem(build_redis_key(PERSISTED_SETTINGS_KEYS_REDIS_KEY), setting_key)
    end

    cleared == 1
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

  #
  # A/B testing analysis
  #

  def record_ab_testing_conversion(setting_definition, variant, scope, time)
    timestamp_ms = (time.to_f * 1000).to_i

    key = build_redis_key(CONVERSIONS_NAMESPACE, setting_definition.key, variant.id)
    tracking_key = build_redis_key(CONVERSIONS_KEYS_NAMESPACE, setting_definition.key)

    redis.pipelined do |pipeline|
      pipeline.zadd(key, timestamp_ms, scope.to_s, nx: true)
      pipeline.expire(key, CONVERSIONS_TTL)
      pipeline.sadd(tracking_key, key)
    end
  end

  def read_ab_testing_conversions(setting_definition, variants)
    keys = variants.map { |v| build_redis_key(CONVERSIONS_NAMESPACE, setting_definition.key, v.id) }

    results = redis.pipelined do |pipeline|
      keys.each { |key| pipeline.zrange(key, 0, -1, withscores: true) }
    end

    variants.zip(results).to_h
  end

  def clear_ab_testing_conversions(setting_key)
    tracking_key = build_redis_key(CONVERSIONS_KEYS_NAMESPACE, setting_key)
    keys = redis.smembers(tracking_key)
    return unless keys.any?

    redis.pipelined do |pipeline|
      keys.each { |key| pipeline.del(key) }
      pipeline.del(tracking_key)
    end
  end

  private

  attr_reader :redis, :redis_namespace

  def redis_key_for(setting_key)
    build_redis_key(SETTINGS_NAMESPACE, setting_key)
  end

  def build_redis_key(*parts)
    [redis_namespace, *parts].join(":")
  end
end
