# frozen_string_literal: true

class Fino::Redis::Adapter
  include Fino::Adapter

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

  def write(setting_definition, value, **context)
    key = redis_key_for(setting_definition)
    hash_key = redis_hash_value_key_for(context)
    value = setting_definition.type_class.serialize(value)

    redis.hset(key, hash_key, value)
  end

  def write_variants(setting_definition, variants_to_values)
    key = redis_key_for(setting_definition)

    variants_hash = variants_to_values.each_with_object({}) do |(variant, value), memo|
      memo["#{VARIANT_PREFIX}/#{variant.id}/#{variant.percentage}/#{VALUE_KEY}"] = value.to_s
    end

    redis.mapped_hmset(key, variants_hash)
  end

  def read_multi(setting_definitions)
    keys = setting_definitions.map { |definition| redis_key_for(definition) }

    redis.pipelined do |pipeline|
      keys.each { |key| pipeline.hgetall(key) }
    end
  end

  def fetch_value_from(raw_adapter_data)
    raw_adapter_data.key?(VALUE_KEY) ? raw_adapter_data.delete(VALUE_KEY) : Fino::EMPTINESS
  end

  def fetch_scoped_values_from(raw_adapter_data)
    raw_adapter_data.each_with_object({}) do |(key, value), memo|
      next unless key.start_with?("#{SCOPE_PREFIX}/")

      scope = key.split("/", 3)[1]
      memo[scope] = value
    end
  end

  def fetch_variant_values_from(raw_adapter_data)
    raw_adapter_data.each_with_object({}) do |(key, value), memo|
      next unless key.start_with?("#{VARIANT_PREFIX}/")

      id, percentage = key.split("/", 4)[1..2]
      memo[Fino::Variant.new(id, percentage.to_f)] = value
    end
  end

  private

  attr_reader :redis, :redis_namespace

  def redis_hash_value_key_for(context)
    context[:scope] ? "#{SCOPE_PREFIX}/#{context[:scope]}/#{VALUE_KEY}" : VALUE_KEY
  end

  def redis_key_for(setting_definition)
    "#{redis_namespace}:#{setting_definition.path.join(':')}"
  end
end
