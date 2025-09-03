# frozen_string_literal: true

class Fino::Redis::Adapter
  include Fino::Adapter

  DEFAULT_REDIS_NAMESPACE = "fino"
  VALUE_KEY = "v"

  def initialize(redis, namespace: DEFAULT_REDIS_NAMESPACE)
    @redis = redis
    @redis_namespace = namespace
  end

  def read(setting_definition)
    redis.hgetall(redis_key_for(setting_definition))
  end

  def write(setting_definition, value)
    redis.hset(redis_key_for(setting_definition), VALUE_KEY, setting_definition.class.serialize(value))
  end

  def read_multi(setting_definitions)
    keys = setting_definitions.map { |definition| redis_key_for(definition) }

    redis.pipelined do |pipeline|
      keys.each { |key| pipeline.hgetall(key) }
    end
  end

  def fetch_value_from(raw_adapter_data)
    raw_adapter_data.key?(VALUE_KEY) ? raw_adapter_data.delete(VALUE_KEY) : Fino::Setting::UNSET_VALUE
  end

  private

  attr_reader :redis, :redis_namespace

  def redis_key_for(setting_definition)
    "#{redis_namespace}:#{setting_definition.path.join(":")}"
  end
end
