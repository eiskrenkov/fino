# frozen_string_literal: true

require "redis"

class Fino::Redis::Adapter
  include Fino::Adapter

  DEFAULT_REDIS_NAMESPACE = "fino"

  def initialize(registry, namespace:, **options)
    super(registry)

    @redis_namespace = namespace
    @redis = ::Redis.new(options)
  end

  protected

  def read(setting_definition)
    redis.hgetall(redis_key_for(setting_definition))
  end

  def write(setting_definition, value)
    redis.hset(redis_key_for(setting_definition), "value", setting_definition.class.serialize(value))
  end

  def read_multi(setting_definitions)
    keys = setting_definitions.map { |definition| redis_key_for(definition) }

    redis.pipelined do |pipeline|
      keys.each { |key| pipeline.hgetall(key) }
    end
  end

  private

  attr_reader :redis, :redis_namespace

  def redis_key_for(setting_definition)
    if setting_definition.section_name
      "#{redis_namespace}:#{setting_definition.section_name}:#{setting_definition.setting_name}"
    else
      "#{redis_namespace}:#{setting_definition.setting_name}"
    end
  end
end

Fino::Adapter::Registry.register :redis, Fino::Redis::Adapter
